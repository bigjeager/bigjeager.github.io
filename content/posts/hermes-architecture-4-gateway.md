---
title: "Hermes Agent 架构解读（四）：Gateway 网关"
date: 2026-05-09T10:33:00+08:00
draft: false
tags: ["AI", "Agent", "Hermes", "架构"]
categories: ["技术"]
series: ["Hermes架构解读"]
series_order: 4
---

## Gateway 概述

Gateway 是 Hermes 的消息平台网关，负责：

- 启动和管理各平台适配器
- 消息收发和路由
- 会话生命周期管理
- 斜杠命令处理

核心文件：`gateway/run.py`（约 15,000 行）

## 平台适配器

`gateway/platforms/` 包含约 25+ 平台适配器：

```
platforms/
├── telegram.py      # Telegram Bot API
├── discord.py       # Discord Bot
├── slack.py         # Slack App
├── signal.py        # Signal
├── matrix.py        # Matrix
├── whatsapp.py      # WhatsApp
├── weixin.py        # 微信
├── wecom.py         # 企业微信
├── feishu.py        # 飞书
├── dingtalk.py      # 钉钉
├── qqbot/           # QQ Bot
├── email.py         # Email (IMAP/SMTP)
├── sms.py           # SMS
├── homeassistant.py # Home Assistant
├── yuanbao.py       # 腾讯元宝
├── webhook.py       # Webhook
├── api_server.py    # REST API
└── ...
```

### 基类设计

```python
# gateway/platforms/base.py
class BasePlatform:
    async def start(self):
        """启动平台连接"""
        
    async def stop(self):
        """停止平台"""
        
    async def send_message(self, chat_id, message):
        """发送消息"""
        
    async def receive_message(self) -> Message:
        """接收消息"""
```

## GatewayRunner 类

```python
# gateway/run.py
class GatewayRunner:
    def __init__(self):
        self.platforms = {}      # 活动平台实例
        self.agent_cache = {}    # Agent 实例缓存
        self.session_db = None   # SQLite 会话存储
    
    async def start_gateway(self):
        """启动所有配置的平台"""
        
    async def handle_message(self, platform, message):
        """处理收到的消息"""
        
    async def send_response(self, platform, chat_id, response):
        """发送响应"""
```

### Agent 缓存管理

为避免重复创建 Agent，使用 LRU 缓存：

```python
_AGENT_CACHE_MAX_SIZE = 128
_AGENT_CACHE_IDLE_TTL_SECS = 3600  # 1 小时空闲后清理
```

## 消息处理流程

```
平台消息 → platform.receive_message()
                ↓
         GatewayRunner.handle_message()
                ↓
         查找/创建 Agent (agent_cache)
                ↓
         AIAgent.run_conversation()
                ↓
         处理响应 → platform.send_message()
                ↓
         返回给用户
```

## 斜杠命令

Gateway 支持统一斜杠命令系统：

```python
# hermes_cli/commands.py
COMMAND_REGISTRY = [
    CommandDef(name="help", aliases=["h"], handler=handle_help),
    CommandDef(name="new", aliases=[], handler=handle_new),
    CommandDef(name="usage", aliases=["u"], handler=handle_usage),
    CommandDef(name="logs", aliases=[], handler=handle_logs),
    # ...
]

def resolve_command(name: str) -> CommandDef:
    """解析命令名（支持别名）"""
```

### 命令处理

```python
# gateway/run.py
async def process_command(self, platform, message, command_name):
    """处理斜杠命令"""
    cmd = resolve_command(command_name)
    if cmd:
        result = await cmd.handler(platform, message)
        await self.send_response(platform, message.chat_id, result)
```

## 会话管理

### 会话持久化

```python
# hermes_state.py (SessionDB)
class SessionDB:
    def __init__(self, db_path="~/.hermes/sessions.db"):
        self.conn = sqlite3.connect(db_path)
        # FTS5 全文搜索
        self.conn.execute("""
            CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts 
            USING fts5(content, tokenize='unicode61')
        """)
    
    def save_message(self, session_id, role, content):
        """保存消息"""
        
    def get_messages(self, session_id):
        """获取会话历史"""
        
    def search_sessions(self, query):
        """全文搜索"""
```

### 自动恢复机制

Gateway 支持中断后自动恢复：

```python
_AUTO_CONTINUE_FRESHNESS_SECS_DEFAULT = 3600  # 1 小时内恢复

def _coerce_gateway_timestamp(value) -> Optional[float]:
    """解析时间戳判断会话是否新鲜"""
```

## 平台特定处理

### Telegram

```python
# telegram.py 特殊处理
_TELEGRAM_COMMAND_MENTION_RE = re.compile(r"/([A-Za-z0-9][A-Za-z0-9_-]*)")

def _telegramize_command_mentions(text: str) -> str:
    """将斜杠命令转换为 Telegram 可点击格式"""
```

Telegram 命令名限制：只允许小写字母、数字和下划线。

### 元宝 (Yuanbao)

```python
# yuanbao.py
class YuanbaoPlatform(BasePlatform):
    async def handle_message(self, message):
        """处理元宝群聊消息"""
        # 支持 @提及、多媒体
```

## 新增平台指南

参见 `gateway/platforms/ADDING_A_PLATFORM.md`：

1. 创建 `platforms/new_platform.py`
2. 继承 `BasePlatform`
3. 实现 `start()`, `stop()`, `send_message()`, `receive_message()`
4. 在 `config.yaml` 配置启用
5. 添加必要的环境变量到 `.env`

---

**下一章**: [技能系统](hermes-architecture-5-skills) - 知识注入与扩展