---
title: "Hermes Agent 架构解读（六）：状态管理"
date: 2026-05-09T10:35:00+08:00
draft: false
tags: ["AI", "Agent", "Hermes", "架构"]
categories: ["技术"]
series: ["Hermes架构解读"]
series_order: 6
---

## 状态管理概述

Hermes 的状态管理包含：

- **Session**: 会话历史持久化
- **Memory**: 跨会话记忆
- **Config**: 用户配置

## Session 会话管理

### 数据库结构

`hermes_state.py` 使用 SQLite + FTS5：

```python
# hermes_state.py (约 2,600 行)
class SessionDB:
    def __init__(self, db_path=None):
        if db_path is None:
            db_path = os.path.join(get_hermes_home(), "sessions.db")
        self.conn = sqlite3.connect(db_path)
        
        # 消息表
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY,
                session_id TEXT,
                role TEXT,
                content TEXT,
                timestamp REAL,
                tool_calls TEXT,
                tool_results TEXT
            )
        """)
        
        # FTS5 全文搜索
        self.conn.execute("""
            CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts 
            USING fts5(content, tokenize='unicode61')
        """)
```

### 核心方法

```python
def save_message(self, session_id, role, content, **metadata):
    """保存消息到会话"""

def get_messages(self, session_id, limit=None, offset=None):
    """获取会话历史"""

def search_sessions(self, query, limit=10):
    """全文搜索历史对话"""

def get_recent_sessions(self, limit=10):
    """获取最近会话"""

def delete_session(self, session_id):
    """删除会话"""

def export_session(self, session_id, format="json"):
    """导出会话"""
```

## session_search 工具

```python
# tools/session_search_tool.py
def session_search(query=None, limit=3, role_filter=None):
    """搜索历史对话
    
    Args:
        query: 搜索关键词 (None 时返回最近会话)
        limit: 返回数量
        role_filter: 角色过滤 (如 "user,assistant")
    
    Returns:
        会话摘要列表
    """
```

使用示例：

- `session_search()` - 返回最近会话
- `session_search("docker")` - 搜索包含 "docker" 的对话
- `session_search("python NOT java")` - 搜索包含 python 但不含 java

## Memory 跨会话记忆

### Memory 工具

```python
# tools/memory_tool.py
def memory(action, target, content=None, old_text=None):
    """管理持久记忆
    
    Actions:
        - add: 添加记忆
        - replace: 替换记忆
        - remove: 删除记忆
    
    Targets:
        - 'memory': Agent 个人笔记
        - 'user': 用户档案
    """
```

### 存储位置

```
~/.hermes/
├── memory/
│   ├── memory.md      # Agent 个人笔记
│   └── user_profile.md # 用户档案
```

### 内存注入

记忆在每个 turn 自动注入到 System Prompt：

```python
# agent/memory_manager.py
def build_memory_context_block():
    """构建记忆上下文块"""
    memory_content = read_memory()
    user_profile = read_user_profile()
    
    return f"""
══════════════════════════════════════════════
MEMORY (your personal notes)
══════════════════════════════════════════════
{memory_content}

══════════════════════════════════════════════
USER PROFILE (who the user is)
══════════════════════════════════════════════
{user_profile}
"""
```

### 记忆最佳实践

**应该保存：**
- 用户偏好（语言、风格）
- 环境信息（OS、工具）
- 项目约定
- 用户修正和反馈

**不应该保存：**
- 任务进度（用 session_search）
- 临时状态
- 一次性信息

## 配置管理

### 配置文件

```yaml
# ~/.hermes/config.yaml
model:
  default: "qwen3.5-plus"
  fallback: "claude-sonnet-4"

gateway:
  telegram:
    enabled: true
    token: "${TELEGRAM_BOT_TOKEN}"
  discord:
    enabled: false

agent:
  max_iterations: 90
  gateway_timeout: 1800

skills:
  enabled: ["claude-code", "jupyter-live-kernel"]
```

### 配置读取

```python
# hermes_cli/config.py
def cfg_get(key, default=None):
    """读取配置
    
    支持嵌套: cfg_get("model.default")
    支持环境变量: "${TELEGRAM_BOT_TOKEN}"
    """
```

### 环境变量

```bash
# ~/.hermes/.env
TELEGRAM_BOT_TOKEN=xxx
DISCORD_BOT_TOKEN=xxx
OPENAI_API_KEY=xxx
ANTHROPIC_API_KEY=xxx
```

## 轨迹压缩

长对话需要压缩以节省 token：

```python
# trajectory_compressor.py (约 2,000 行)
class TrajectoryCompressor:
    def compress_messages(self, messages, target_tokens):
        """压缩消息历史"""
        
        # 策略:
        # 1. 保留最近的完整消息
        # 2. 压缩中间消息为摘要
        # 3. 保留关键 tool calls
```

## 状态持久化流程

```
用户消息
    ↓
SessionDB.save_message(session_id, "user", content)
    ↓
AIAgent.run_conversation()
    ↓
处理响应
    ↓
SessionDB.save_message(session_id, "assistant", content, tool_calls=...)
    ↓
检查 memory 更新
    ↓
返回响应
```

---

## 系列总结

Hermes Agent 架构核心要点：

1. **分层设计**: CLI → Gateway → AIAgent → Tools
2. **自注册工具**: 模块导入时自动注册
3. **工具集抽象**: 按场景组合工具
4. **多平台 Gateway**: 统一适配器接口
5. **技能注入**: 知识作为上下文
6. **SQLite + FTS5**: 持久化与搜索

---

> 本系列基于 Hermes Agent v0.12 源代码分析完成。