---
title: "Hermes Agent 架构解读（一）：概述"
date: 2026-05-09T10:30:00+08:00
draft: false
tags: ["AI", "Agent", "Hermes", "架构"]
categories: ["技术"]
series: ["Hermes架构解读"]
series_order: 1
---

## 什么是 Hermes Agent？

Hermes Agent 是一个功能强大的 AI Agent 框架，支持多平台消息集成、工具调用、技能系统等特性。本文将从整体架构入手，带你深入理解这个框架的设计理念。

## 整体架构

Hermes 采用分层架构设计，主要包含以下核心模块：

```
hermes-agent/
├── run_agent.py          # 核心对话引擎 - AIAgent 类
├── cli.py                # CLI 交互层
├── model_tools.py        # 工具编排层
├── toolsets.py           # 工具集定义
├── gateway/              # 消息平台网关
│   └── platforms/        # 各平台适配器 (Telegram, Discord, etc.)
├── tools/                # 工具实现
├── agent/                # Agent 内部模块 (memory, caching, compression)
├── skills/               # 技能系统
├── plugins/              # 插件扩展
├── hermes_state.py       # 状态存储 (SQLite + FTS5)
└── cron/                 # 定时任务调度
```

## 核心设计理念

### 1. 工具注册系统

Hermes 使用**自注册模式**：每个工具文件在导入时自动调用 `registry.register()` 注册其 schema、handler 和 metadata。这种设计使得：

- 新增工具只需在 `tools/` 目录创建文件
- 无需手动维护工具列表
- 自动发现机制简化了扩展流程

```python
# tools/registry.py
from tools.registry import registry

registry.register(
    name="terminal",
    schema={...},
    handler=terminal_handler,
    toolset="terminal"
)
```

### 2. 工具集抽象

工具集允许将工具按场景分组，支持组合：

```python
# toolsets.py
TOOLSETS = {
    "web": {
        "tools": ["web_search", "web_extract"],
        "includes": []
    },
    "full_stack": {
        "tools": ["terminal", "file"],
        "includes": ["web", "browser"]  # 包含其他工具集
    }
}
```

### 3. Gateway 网关

Gateway 负责与各消息平台对接，采用适配器模式：

- **Telegram**: `gateway/platforms/telegram.py`
- **Discord**: `gateway/platforms/discord.py`
- **Slack**: `gateway/platforms/slack.py`
- **微信/飞书**: `weixin.py`, `feishu.py`
- **更多**: Signal, Matrix, WhatsApp, SMS, Email...

每个平台适配器继承 `base.py` 中的基类，统一处理消息收发和会话管理。

### 4. 会话状态管理

使用 SQLite + FTS5 实现持久化存储：

- 会话历史存储
- 全文搜索检索历史对话
- 用户配置持久化
- 内存管理

## 数据流图

```
用户消息 → Gateway → AIAgent.run_conversation()
                           ↓
                    构建 System Prompt
                           ↓
                    调用 LLM API (OpenAI 格式)
                           ↓
                    解析 Tool Calls → handle_function_call()
                           ↓
                    执行工具 → 返回结果
                           ↓
                    继续对话循环 → 最终响应
                           ↓
                    Gateway → 用户
```

## 配置架构

用户配置位于 `~/.hermes/`：

```
~/.hermes/
├── config.yaml      # 主配置文件
├── .env             # API 密钥
├── logs/            # 日志目录
│   ├── agent.log
│   ├── errors.log
│   └── gateway.log
├── sessions.db      # SQLite 会话存储
├── skills/          # 用户自定义技能
└── cron/            # 定时任务
```

## 系列文章预告

本系列将深入探讨：

1. **[概述]** - 整体架构设计 ✅
2. **核心引擎** - AIAgent 类与对话循环
3. **工具系统** - 注册、发现与执行机制
4. **Gateway 网关** - 多平台消息集成
5. **技能系统** - 知识注入与扩展
6. **状态管理** - Session 和 Memory

---

> 本系列基于 Hermes Agent v0.12 源代码分析，代码位于 `~/.hermes/hermes-agent/`。