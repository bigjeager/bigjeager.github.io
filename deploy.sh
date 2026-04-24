#!/bin/bash
#
# Hugo 博客部署脚本
# 用法：./deploy.sh [commit message]
#

set -e

# 配置
HUGO_BIN="${HOME}/bin/hugo"
DEPLOY_BRANCH="main"
BUILD_DIR="public"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  Hugo 博客部署脚本${NC}"
echo -e "${GREEN}================================${NC}"

# 检查 Hugo
if [ ! -f "$HUGO_BIN" ]; then
    echo -e "${RED}错误：Hugo 未找到，请先安装 Hugo${NC}"
    exit 1
fi

# 检查是否在正确的目录
if [ ! -f "hugo.toml" ]; then
    echo -e "${RED}错误：请在 Hugo 项目根目录运行此脚本${NC}"
    exit 1
fi

# 获取提交信息
COMMIT_MSG="${1:-更新博客内容}"

# 构建网站
echo -e "${YELLOW}[1/4] 正在构建网站...${NC}"
$HUGO_BIN --minify --gc

# 检查构建结果
if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}错误：构建失败${NC}"
    exit 1
fi

# 切换到部署分支
echo -e "${YELLOW}[2/4] 切换到部署分支 ${DEPLOY_BRANCH}...${NC}"
git worktree add -f temp-deploy "$DEPLOY_BRANCH" 2>/dev/null || {
    git checkout --orphan "$DEPLOY_BRANCH"
    git commit --allow-empty -m "Initial commit"
    git checkout -
    git worktree add temp-deploy "$DEPLOY_BRANCH"
}

# 复制构建文件
echo -e "${YELLOW}[3/4] 复制构建文件...${NC}"
rm -rf temp-deploy/*
cp -r $BUILD_DIR/* temp-deploy/
cp -r $BUILD_DIR/.* temp-deploy/ 2>/dev/null || true

# 提交并推送
echo -e "${YELLOW}[4/4] 提交并推送...${NC}"
cd temp-deploy
git add .
git commit -m "$COMMIT_MSG" || echo "没有变化需要提交"
git push origin "$DEPLOY_BRANCH"
cd ..

# 清理
git worktree remove temp-deploy

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  ✅ 部署完成！${NC}"
echo -e "${GREEN}  访问：https://bigjeager.github.io/${NC}"
echo -e "${GREEN}================================${NC}"
