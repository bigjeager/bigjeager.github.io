#!/bin/bash
#
# 推送到 GitHub 并部署
#

set -e

echo "🚀 推送到 GitHub 并部署"
echo "========================"
echo ""

# 检查 git 状态
echo "📊 检查 git 状态..."
git status -s

echo ""
read -p "确认要推送这些更改吗？(y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "❌ 取消推送"
    exit 1
fi

# 添加并提交
echo ""
echo "📝 添加并提交更改..."
git add -A
git status -s | grep -q "^??" && git add -A
if git diff --cached --quiet; then
    echo "⚠️ 没有更改需要提交"
else
    read -p "输入提交信息 (默认：更新博客内容): " commit_msg
    commit_msg=${commit_msg:-"更新博客内容"}
    git commit -m "$commit_msg"
fi

# 推送
echo ""
echo "🚀 推送到 GitHub..."
git push origin hugo-source

echo ""
echo "✅ 推送成功！"
echo ""
echo "📱 查看 GitHub Actions 部署状态:"
echo "   https://github.com/bigjeager/bigjeager.github.io/actions"
echo ""
echo "🌐 部署完成后访问:"
echo "   https://bigjeager.github.io/posts/osaka-family-trip-2024/"
echo ""
