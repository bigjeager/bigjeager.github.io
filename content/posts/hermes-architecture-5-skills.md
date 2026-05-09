---
title: "Hermes Agent 架构解读（五）：技能系统"
date: 2026-05-09T10:34:00+08:00
draft: false
tags: ["AI", "Agent", "Hermes", "架构"]
categories: ["技术"]
series: ["Hermes架构解读"]
series_order: 5
---

## 技能系统概述

技能是 Hermes 的**知识注入机制**，允许为特定任务场景提供：

- 专用指令
- 工作流程
- 参考文档
- 脚本和模板

## 技能目录结构

```
skills/
├── autonomous-ai-agents/
│   ├── claude-code/SKILL.md
│   ├── codex/SKILL.md
│   ├── hermes-agent/SKILL.md
│   └── ...
├── creative/
│   ├── ascii-art/SKILL.md
│   ├── pixel-art/SKILL.md
│   └── ...
├── mlops/
│   ├── whisper/SKILL.md
│   ├── llama-cpp/SKILL.md
│   └── ...
├── software-development/
│   ├── writing-plans/SKILL.md
│   ├── systematic-debugging/SKILL.md
│   └── ...
└── ... (约 27 个类别)

optional-skills/    # 较大/小众技能，默认不激活
~/.hermes/skills/   # 用户自定义技能
```

## SKILL.md 格式

每个技能是一个目录，包含 `SKILL.md` 文件：

```markdown
---
name: claude-code
description: Delegate coding to Claude Code CLI
category: autonomous-ai-agents
version: 1.0
---

## 触发条件
当用户请求编写代码、创建 PR、或需要复杂编程任务时使用。

## 工作流程

1. 确认任务范围
2. 运行 `claude --acp --stdio`
3. 监控输出并返回结果

## 命令示例
```bash
claude --acp --stdio --model claude-opus-4-6
```

## 陷阱
- 需要安装 Claude CLI
- 需要 Anthropic API key

## 参考文件
- [API文档](references/api.md)
- [脚本模板](scripts/run.sh)
```

### Frontmatter 字段

| 字段 | 说明 |
|------|------|
| `name` | 技能名称 |
| `description` | 简短描述 |
| `category` | 类别目录 |
| `version` | 版本号 |
| `requires` | 依赖工具 |

## 技能加载机制

### 启动时扫描

```python
# agent/skill_commands.py
def scan_skills_directory():
    """扫描 ~/.hermes/skills/ 和 skills/"""
    skills = []
    for path in [HERMES_SKILLS_DIR, REPO_SKILLS_DIR]:
        for category in os.listdir(path):
            for skill_name in os.listdir(f"{path}/{category}"):
                skill_file = f"{path}/{category}/{skill_name}/SKILL.md"
                if os.path.exists(skill_file):
                    skills.append(skill_name)
    return skills
```

### 注入方式

技能内容作为 **User Message** 注入（而非 System Prompt），以保持 prompt caching：

```python
def build_skills_system_prompt(enabled_skills):
    """构建技能提示"""
    content = "## Skills (mandatory)\n"
    for skill in enabled_skills:
        skill_md = read_skill(skill)
        content += f"\n### {skill}\n{skill_md}\n"
    return content
```

## 技能工具

用户可通过工具管理技能：

```python
# tools/skills_tool.py
def skills_list(category=None) -> list:
    """列出可用技能"""

def skill_view(name, file_path=None) -> str:
    """查看技能内容"""

def skill_manage(action, name, content=None, ...):
    """管理技能: create, patch, edit, delete"""
```

## 技能使用流程

```
用户: "帮我用 Claude Code 写个 PR"
       ↓
Agent 匹配技能: claude-code
       ↓
skill_view("claude-code") 加载 SKILL.md
       ↓
注入到上下文
       ↓
Agent 按技能指引执行
       ↓
运行 claude --acp --stdio
       ↓
返回结果
```

## 技能扩展

### 创建新技能

```python
# 使用 skill_manage 工具
skill_manage(
    action="create",
    name="my-custom-skill",
    category="custom",
    content="SKILL.md 内容..."
)
```

或手动创建：

```bash
mkdir ~/.hermes/skills/my-skill
cat > ~/.hermes/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: My custom workflow
---
# 工作流程
...
EOF
```

### 添加辅助文件

```
~/.hermes/skills/my-skill/
├── SKILL.md           # 主文件
├── references/        # 参考文档
│   └── api.md
├── templates/         # 模板文件
│   └── config.yaml
├── scripts/           # 脚本
│   └── run.py
└── assets/            # 资源文件
```

## Optional Skills

一些较大的技能放在 `optional-skills/`，默认不激活：

- `email/` - Himalaya CLI 邮件工具
- `blockchain/` - 区块链相关
- `health/` - 健康追踪
- `security/` - 安全测试

需要手动启用：

```yaml
# config.yaml
skills:
  enabled:
    - email
    - blockchain
```

---

**下一章**: [状态管理](hermes-architecture-6-state) - Session 和 Memory