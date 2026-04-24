# BigJeager 的博客

[![Deploy](https://github.com/bigjeager/bigjeager.github.io/actions/workflows/deploy.yml/badge.svg)](https://github.com/bigjeager/bigjeager.github.io/actions/workflows/deploy.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

📝 我的个人博客 - 记录技术、生活与思考

**在线访问：** https://bigjeager.github.io/

---

## 🛠️ 技术栈

| 组件 | 技术 |
|------|------|
| 静态生成器 | [Hugo](https://gohugo.io/) v0.120 |
| 主题 | [PaperMod](https://github.com/adityatelange/hugo-PaperMod) |
| 托管 | [GitHub Pages](https://pages.github.com/) |

---

## 🚀 快速开始

### 前置要求

- Hugo v0.120+
- Git

### 本地开发

```bash
# 1. 克隆仓库
git clone https://github.com/bigjeager/bigjeager.github.io.git
cd bigjeager.github.io

# 2. 初始化子模块（主题）
git submodule init
git submodule update

# 3. 启动本地服务器
make serve
# 或者：hugo server --buildDrafts

# 访问 http://localhost:1313
```

### 创建新文章

```bash
# 使用 Makefile
make post

# 或直接使用 Hugo
hugo new content posts/文章标题.md
```

### 构建网站

```bash
make build
# 输出在 public/ 目录
```

### 部署到 GitHub Pages

```bash
# 方式 1：使用部署脚本
make deploy

# 方式 2：手动部署
./deploy.sh "提交信息"
```

---

## 📁 项目结构

```
bigjeager.github.io/
├── content/              # 文章内容
│   ├── posts/           # 博客文章
│   └── about.md         # 关于页面
├── themes/              # 主题
│   └── PaperMod/        # PaperMod 主题
├── static/              # 静态资源
├── layouts/             # 自定义布局
├── hugo.toml            # Hugo 配置
├── Makefile             # 构建命令
├── deploy.sh            # 部署脚本
└── README.md            # 本文件
```

---

## 📝 常用命令

| 命令 | 说明 |
|------|------|
| `make help` | 显示所有命令 |
| `make serve` | 本地预览 |
| `make build` | 构建网站 |
| `make post` | 创建新文章 |
| `make deploy` | 部署到 GitHub |
| `make clean` | 清理构建文件 |
| `make check` | 检查环境 |
| `make sync` | 更新主题 |

---

## 🎨 主题配置

主题使用 [PaperMod](https://github.com/adityatelange/hugo-PaperMod)，配置在 `hugo.toml` 中：

```toml
[params]
  defaultTheme = "auto"  # auto/dark/light
  ShowCodeCopyButtons = true
  ShowShareButtons = true
  ShowReadingTime = true
```

---

## 📄 License

MIT License

---

**最后更新：** 2024 年 4 月 23 日
