#!/usr/bin/env bash
# 部署 www.horsduroot.com 到阿里云 ECS(nginx)
# 用法: ./deploy.sh            # 自动探测 nginx 根目录并同步
#       WEBROOT=/path ./deploy.sh  # 手动指定根目录，跳过探测
set -euo pipefail

SSH_HOST="${SSH_HOST:-wuhao-tutor-ecs}"   # ~/.ssh/config 中的主机别名
SITE_HOST="www.horsduroot.com"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "▶ 目标服务器: $SSH_HOST  站点: $SITE_HOST"

# 1) 探测 nginx 网站根目录（除非已通过环境变量指定）
if [[ -z "${WEBROOT:-}" ]]; then
  echo "▶ 探测 nginx 根目录…"
  WEBROOT="$(ssh "$SSH_HOST" "nginx -T 2>/dev/null | awk '/server_name/{s=\$0} /root /{print s\" || \"\$0}'" \
    | grep -i horsduroot | grep -oE 'root[[:space:]]+[^;]+' | head -1 | awk '{print $2}')" || true
fi

if [[ -z "${WEBROOT:-}" ]]; then
  echo "✗ 未能自动探测到网站根目录。请手动指定：WEBROOT=/your/path ./deploy.sh" >&2
  exit 1
fi
echo "▶ 网站根目录: $WEBROOT"

# 2) 同步（优先 rsync，回退 scp），排除开发/非站点文件
EXCLUDES=(
  --exclude ".git" --exclude ".gitignore" --exclude ".DS_Store"
  --exclude "assets_orig" --exclude "deploy.sh" --exclude "README.md"
  --exclude "company-homepage-*.png"
)

if command -v rsync >/dev/null 2>&1; then
  echo "▶ 使用 rsync 同步…"
  rsync -avz --delete "${EXCLUDES[@]}" "$SRC_DIR"/ "$SSH_HOST:$WEBROOT/"
else
  echo "▶ rsync 不可用，回退到 scp（不删除服务器多余文件）…"
  scp -r "$SRC_DIR"/index.html "$SRC_DIR"/styles.css "$SRC_DIR"/script.js \
        "$SRC_DIR"/robots.txt "$SRC_DIR"/sitemap.xml "$SRC_DIR"/assets \
        "$SSH_HOST:$WEBROOT/"
fi

# 3) 校验线上首页可访问
echo "▶ 校验 https://$SITE_HOST …"
code="$(curl -s -o /dev/null -w '%{http_code}' "https://$SITE_HOST/")"
echo "  HTTP $code"
[[ "$code" == "200" ]] && echo "✓ 部署完成" || { echo "✗ 首页返回非 200"; exit 1; }
