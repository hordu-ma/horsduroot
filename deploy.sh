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
    | grep -i horsduroot | grep -v certbot | grep -oE 'root[[:space:]]+[^;]+' | head -1 | awk '{print $2}')" || true
fi

if [[ -z "${WEBROOT:-}" ]]; then
  echo "✗ 未能自动探测到网站根目录。请手动指定：WEBROOT=/your/path ./deploy.sh" >&2
  exit 1
fi
echo "▶ 网站根目录: $WEBROOT"

EXCLUDES=(
  --exclude ".git" --exclude ".gitignore" --exclude ".DS_Store"
  --exclude ".claude" --exclude "assets_orig" --exclude "deploy.sh"
  --exclude "server-deploy.sh"
  --exclude "README.md" --exclude "company-homepage-*.png"
)

# 2) 缓存破解：css/js 设了 30 天强缓存，必须给链接打内容版本号，
#    否则改了 css/js、老访客仍用旧缓存 → 新 HTML 配旧 CSS，页面错位。
#    版本号 = styles.css + script.js 的内容哈希；改了才变，没改则缓存继续命中。
VER="$(cat "$SRC_DIR/styles.css" "$SRC_DIR/script.js" | shasum | cut -c1-8)"
echo "▶ 资源版本号 v=$VER"

# 暂存目录：复制要发布的文件，并把 index.html 里 css/js 链接的 ?v= 替换成该版本号
#（源文件保持 ?v=dev 不动，便于本地开发）
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
rsync -a "${EXCLUDES[@]}" "$SRC_DIR"/ "$STAGE"/
sed -E "s#(styles\.css|script\.js)(\?v=[A-Za-z0-9._-]+)?#\1?v=$VER#g" \
    "$SRC_DIR/index.html" > "$STAGE/index.html"

# 3) 同步（优先 rsync，回退 scp）
if command -v rsync >/dev/null 2>&1; then
  echo "▶ 使用 rsync 同步…"
  rsync -avz --delete "${EXCLUDES[@]}" "$STAGE"/ "$SSH_HOST:$WEBROOT/"
else
  echo "▶ rsync 不可用，回退到 scp（不删除服务器多余文件）…"
  scp -r "$STAGE"/index.html "$STAGE"/styles.css "$STAGE"/script.js \
        "$STAGE"/robots.txt "$STAGE"/sitemap.xml "$STAGE"/assets \
        "$SSH_HOST:$WEBROOT/"
fi

# 4) 校验：首页可访问 + 版本号已生效 + 该版本 css 可拉取
echo "▶ 校验 https://$SITE_HOST …"
code="$(curl -s -o /dev/null -w '%{http_code}' "https://$SITE_HOST/")"
echo "  首页 HTTP $code"
live_ver="$(curl -s "https://$SITE_HOST/" | grep -oE 'styles\.css\?v=[A-Za-z0-9]+' | head -1)"
css_code="$(curl -s -o /dev/null -w '%{http_code}' "https://$SITE_HOST/styles.css?v=$VER")"
echo "  线上引用: ${live_ver:-未找到}  | styles.css?v=$VER -> HTTP $css_code"
if [[ "$code" == "200" && "$live_ver" == "styles.css?v=$VER" && "$css_code" == "200" ]]; then
  echo "✓ 部署完成（版本号已生效，老访客也会拉到新 CSS）"
else
  echo "✗ 部署校验未通过"; exit 1
fi
