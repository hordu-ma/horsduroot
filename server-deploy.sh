#!/usr/bin/env bash
# 在服务器本机运行（如通过阿里云 VNC/Workbench 控制台），从 GitHub 拉取并发布站点。
# 用法（在服务器上）:
#   cd /tmp && rm -rf horsduroot && git clone https://github.com/hordu-ma/horsduroot.git \
#     && bash horsduroot/server-deploy.sh
# 或指定根目录:  WEBROOT=/your/path bash horsduroot/server-deploy.sh
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1) 探测 nginx 网站根目录
if [[ -z "${WEBROOT:-}" ]]; then
  WEBROOT="$(nginx -T 2>/dev/null \
    | awk '/server_name/{s=$0} /root /{print s" || "$0}' \
    | grep -i horsduroot | grep -oE 'root[[:space:]]+[^;]+' | head -1 | awk '{print $2}')" || true
fi
# 退路：取任意 server 块的 root
if [[ -z "${WEBROOT:-}" ]]; then
  WEBROOT="$(nginx -T 2>/dev/null | grep -oE 'root[[:space:]]+[^;]+' | head -1 | awk '{print $2}')" || true
fi
if [[ -z "${WEBROOT:-}" ]]; then
  echo "✗ 未能探测到网站根目录。请手动指定：WEBROOT=/your/path bash server-deploy.sh" >&2
  exit 1
fi
echo "▶ 网站根目录: $WEBROOT"

# 2) 备份当前线上文件
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/tmp/horsduroot-backup-$TS.tar.gz"
tar -czf "$BACKUP" -C "$WEBROOT" . 2>/dev/null && echo "▶ 已备份旧站点: $BACKUP"

# 3) 同步站点文件（排除非站点文件）
rsync -av --delete \
  --exclude ".git" --exclude ".gitignore" --exclude ".claude" \
  --exclude "assets_orig" --exclude "deploy.sh" --exclude "server-deploy.sh" \
  --exclude "README.md" --exclude "company-homepage-*.png" \
  "$SRC_DIR"/ "$WEBROOT"/

# 4) 校验
echo "▶ 校验本机首页…"
code="$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/ -H 'Host: www.horsduroot.com')"
echo "  HTTP $code"
echo "✓ 发布完成。回滚命令： tar -xzf $BACKUP -C $WEBROOT"
