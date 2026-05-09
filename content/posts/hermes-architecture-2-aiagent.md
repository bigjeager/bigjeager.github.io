---
title: "Hermes Agent 架构解读（二）：核心引擎 AIAgent"
date: 2026-05-09T10:31:00+08:00
draft: false
tags: ["AI", "Agent", "Hermes", "架构"]
categories: ["技术"]
series: ["Hermes架构解读"]
series_order: 2
---

## AIAgent 类概览

`run_agent.py` 中的 `AIAgent` 类是 Hermes 的核心引擎，负责：

- LLM API 调用
- 工具调用循环
- 消息历史管理
- 预算和中断控制

该文件约 **14,000 行代码**，是整个框架的心脏。

## 类结构

```python
class AIAgent:
    def __init__(self,
        base_url: str = None,         # API endpoint
        api_key: str = None,          # API key
        provider: str = None,         # 提供商名称
        api_mode: str = None,         # "chat_completions" | "codex_responses"
        model: str = "",              # 模型名称
        max_iterations: int = 90,     # 工具调用迭代上限
        enabled_toolsets: list = None,
        disabled_toolsets: list = None,
        quiet_mode: bool = False,
        platform: str = None,         # "cli", "telegram", etc.
        session_id: str = None,
        # ... 还有约 60 个参数
    ): ...

    def chat(self, message: str) -> str:
        """简单接口 - 返回最终响应字符串"""

    def run_conversation(self, user_message: str, 
                         system_message: str = None,
                         conversation_history: list = None,
                         task_id: str = None) -> dict:
        """完整接口 - 返回 dict 包含 final_response + messages"""
```

## 核心对话循环

`run_conversation()` 内部实现了一个同步的迭代循环：

```python
while (api_call_count < self.max_iterations 
       and self.iteration_budget.remaining > 0) \
        or self._budget_grace_call:
    
    if self._interrupt_requested: 
        break
    
    # 调用 LLM
    response = client.chat.completions.create(
        model=model,
        messages=messages,
        tools=tool_schemas
    )
    
    # 处理工具调用
    if response.tool_calls:
        for tool_call in response.tool_calls:
            result = handle_function_call(
                tool_call.name, 
                tool_call.args, 
                task_id
            )
            messages.append(tool_result_message(result))
        api_call_count += 1
    else:
        # 没有工具调用 - 返回最终响应
        return response.content
```

### 关键设计点

1. **IterationBudget**: 线程安全的迭代计数器
   - 父 Agent 上限 `max_iterations` (默认 90)
   - 子 Agent 独立预算 `delegation.max_iterations` (默认 50)

2. **中断机制**: 支持用户中断长时间任务

3. **Grace Call**: 在预算耗尽后允许最后一次响应

## OpenAI 延迟加载

为优化启动速度，OpenAI SDK 采用延迟加载：

```python
# run_agent.py 中的代理模式
class _OpenAIProxy:
    """模块级代理，首次调用时才导入 openai.OpenAI"""
    
    def __call__(self, *args, **kwargs):
        return _load_openai_cls()(*args, **kwargs)

OpenAI = _OpenAIProxy()  # 模块级导出
```

这避免了 ~240ms 的导入延迟。

## 消息格式

消息遵循 OpenAI 格式：

```python
messages = [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "...", "reasoning": "..."},
    {"role": "tool", "content": "...", "tool_call_id": "..."}
]
```

`reasoning` 字段存储模型的推理内容（如 DeepSeek 的思考链）。

## 状态安全写入

为防止崩溃，使用 `_SafeWriter` 包装 stdout/stderr：

```python
class _SafeWriter:
    """捕获 OSError/ValueError，防止管道断裂崩溃"""
    
    def write(self, data):
        try:
            return self._inner.write(data)
        except (OSError, ValueError):
            return len(data) if isinstance(data, str) else 0
```

这在 systemd/Docker/headless 环境中尤为重要。

## Agent 内部模块

`agent/` 目录包含辅助模块：

- **memory_manager.py**: 流式上下文清理、内存构建
- **prompt_builder.py**: System Prompt 构建
- **context_compressor.py**: 上下文压缩
- **model_metadata.py**: 模型元数据、token估算
- **error_classifier.py**: API 错误分类与故障转移
- **retry_utils.py**: 抖动退避重试
- **display.py**: KawaiiSpinner 动画显示
- **trajectory.py**: 轨迹保存

## 代理配置

支持从环境变量读取代理：

```python
def _get_proxy_from_env() -> Optional[str]:
    """检查 HTTPS_PROXY, HTTP_PROXY, ALL_PROXY"""
    for key in ("HTTPS_PROXY", "HTTP_PROXY", "ALL_PROXY", ...):
        value = os.environ.get(key, "").strip()
        if value:
            return normalize_proxy_url(value)
    return None
```

---

**下一章**: [工具系统](hermes-architecture-3-tools) - 工具注册、发现与执行机制