# Hugo 博客 Makefile
# 用法：make [command]

HUGO = ${HOME}/bin/hugo
DEPLOY_BRANCH = main

.PHONY: help build clean serve draft post deploy init

help: ## 显示帮助信息
	@echo "Hugo 博客管理命令"
	@echo "================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## 初始化项目（首次使用）
	@echo "初始化 Hugo 博客..."
	git submodule init
	git submodule update
	@echo "✅ 初始化完成"

build: ## 构建网站
	@echo "构建网站..."
	$(HUGO) --minify --gc
	@echo "✅ 构建完成，输出在 public/ 目录"

clean: ## 清理构建文件
	@echo "清理构建文件..."
	rm -rf public/
	@echo "✅ 清理完成"

serve: ## 本地预览（热重载）
	@echo "启动本地服务器..."
	@echo "访问：http://localhost:1313 或 http://<your-ip>:1313"
	@echo "提示：本地预览模式下，所有链接会自动适配访问地址"
	$(HUGO) server --buildDrafts --bind 0.0.0.0 --renderToMemory --noHTTPCache

draft: ## 创建新草稿
	@read -p "文章标题：" title; \
	$(HUGO) new content posts/$$title.md

post: ## 创建新文章
	@read -p "文章标题：" title; \
	$(HUGO) new content posts/$$title.md; \
	echo "✅ 文章已创建：content/posts/$$title.md"

deploy: ## 部署到 GitHub Pages
	@echo "部署到 GitHub Pages..."
	@read -p "提交信息：" msg; \
	./deploy.sh "$$msg"

preview: ## 构建并预览
	$(HUGO) --minify
	@echo "✅ 构建完成"
	@echo "📂 输出目录：public/"
	@ls -la public/

check: ## 检查 Hugo 版本和主题
	$(HUGO) version
	@echo "---"
	@echo "主题信息:"
	@ls -la themes/PaperMod/.git 2>/dev/null && echo "✅ PaperMod 主题已安装" || echo "❌ 主题未安装"

sync: ## 同步子模块（主题更新）
	@echo "同步主题..."
	git submodule update --remote --merge
	@echo "✅ 主题已更新"

backup: ## 备份当前配置
	@echo "备份配置..."
	tar -czf hugo-backup-$$(date +%Y%m%d-%H%M%S).tar.gz hugo.toml content/ archetypes/
	@echo "✅ 备份完成"
