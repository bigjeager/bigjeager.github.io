---
title: "Hermes Agent 架构解读（三）：工具系统"
date: 2026-05-09T10:32:00+08:00
draft: false
tags: ["AI", "Agent", "Hermes", "架构"]
categories: ["技术"]
series: ["Hermes架构解读"]
series_order: 3
---

## 工具系统概述

Hermes 的工具系统采用**自注册模式**，核心文件：

- `tools/registry.py` - 工具注册中心
- `model_tools.py` - 工具编排层
- `toolsets.py` - 工具集定义
- `tools/*.py` - 各工具实现

## 自注册机制

每个工具文件在导入时自动注册：

```python
# tools/terminal_tool.py
from tools.registry import registry

registry.register(
    name="terminal",
    schema={
        "type": "function",
        "function": {
            "name": "terminal",
            "description": "Execute shell commands",
            "parameters": {...}
        }
    },
    handler=terminal_handler,
    toolset="terminal"
)
```

### registry.py 核心接口

```python
class ToolRegistry:
    def register(self, name, schema, handler, toolset=None, ...):
        """注册工具"""
        
    def get_schema(self, name) -> dict:
        """获取工具 schema"""
        
    def dispatch(self, name, args) -> str:
        """调用工具 handler"""
        
    def discover_builtin_tools():
        """发现所有内置工具"""
```

### 工具发现流程

```python
# model_tools.py
def discover_builtin_tools():
    """导入所有 tools/*.py 文件触发注册"""
    import tools.terminal_tool
    import tools.file_tools
    import tools.browser_tool
    # ... 导入所有工具模块
```

## 工具编排层 model_tools.py

提供统一 API：

```python
def get_tool_definitions(enabled_toolsets, disabled_toolsets, quiet_mode) -> list:
    """获取启用的工具 schemas"""

def handle_function_call(function_name, function_args, task_id) -> str:
    """执行工具调用"""
    
    # 1. 查找 handler
    handler = registry.get_handler(function_name)
    
    # 2. 执行（支持 async）
    if asyncio.iscoroutinefunction(handler):
        result = _run_async(handler(**function_args))
    else:
        result = handler(**function_args)
    
    return result
```

## Async-Sync 桥接

工具 handler 可以是同步或异步函数。`_run_async()` 统一处理：

```python
def _run_async(coro):
    """从同步上下文运行异步 coroutine"""
    
    # 1. 检查是否在 async 上下文中
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        loop = None
    
    if loop and loop.is_running():
        # 在 async 上下文 - 使用线程池
        pool = ThreadPoolExecutor(max_workers=1)
        future = pool.submit(lambda: asyncio.run(coro))
        return future.result(timeout=300)
    
    # 同步上下文 - 使用持久 loop
    tool_loop = _get_tool_loop()
    return tool_loop.run_until_complete(coro)
```

这避免了 "Event loop is closed" 错误。

## 工具集系统 toolsets.py

工具集允许按场景组合工具：

```python
_HERMES_CORE_TOOLS = [
    "web_search", "web_extract",
    "terminal", "process",
    "read_file", "write_file", "patch", "search_files",
    "vision_analyze", "image_generate",
    "skills_list", "skill_view", "skill_manage",
    "browser_navigate", "browser_snapshot", ...
    "execute_code", "delegate_task",
    "cronjob", "send_message", ...
]

TOOLSETS = {
    "web": {
        "description": "Web research tools",
        "tools": ["web_search", "web_extract"],
        "includes": []
    },
    "terminal": {
        "description": "Terminal execution",
        "tools": ["terminal", "process"],
        "includes": []
    },
    "browser": {
        "description": "Browser automation",
        "tools": ["browser_navigate", "browser_snapshot", ...],
        "includes": []
    },
    # 组合工具集
    "full_stack": {
        "tools": ["terminal", "file"],
        "includes": ["web", "browser"]
    }
}
```

### 工具集解析

```python
def resolve_toolset(name: str) -> list:
    """解析工具集到工具名称列表"""
    toolset = TOOLSETS[name]
    tools = toolset["tools"]
    
    # 递归包含的工具集
    for included in toolset["includes"]:
        tools.extend(resolve_toolset(included))
    
    return tools
```

## 内置工具列表

`tools/` 目录包含约 60+ 工具：

| 类别 | 工具 |
|------|------|
| **Web** | `web_search`, `web_extract` |
| **Terminal** | `terminal`, `process` |
| **File** | `read_file`, `write_file`, `patch`, `search_files` |
| **Browser** | `browser_navigate`, `browser_click`, `browser_type`, `browser_vision` |
| **Vision** | `vision_analyze`, `image_generate` |
| **Skills** | `skills_list`, `skill_view`, `skill_manage` |
| **Planning** | `todo`, `memory`, `session_search` |
| **Delegation** | `execute_code`, `delegate_task` |
| **Messaging** | `send_message`, `yuanbao_tools` |
| **Smart Home** | `homeassistant_tool` |
| **TTS** | `tts_tool` |
| **Cron** | `cronjob_tools` |

## 工具执行流程

```
LLM 返回 tool_calls
       ↓
handle_function_call(name, args)
       ↓
registry.dispatch(name, args)
       ↓
handler(**args) → 可能 async
       ↓
_run_async() 桥接
       ↓
返回 JSON 字符串结果
       ↓
封装为 tool message
       ↓
追加到 messages
       ↓
继续 LLM 调用
```

---

**下一章**: [Gateway 网关](hermes-architecture-4-gateway) - 多平台消息集成