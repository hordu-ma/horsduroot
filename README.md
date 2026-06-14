# horsduroot — 山东新工智造科技发展有限公司官网

[www.horsduroot.com](https://www.horsduroot.com/) 的源码。纯静态单页站点，无构建步骤。

## 技术栈

- 纯 HTML / CSS / 原生 JavaScript，无框架、无依赖、无构建。
- 图片资源使用 WebP（带 JPG/PNG 回退），通过 `<picture>` 渐进增强。

## 目录结构

```
index.html        # 单页主文件
styles.css        # 全部样式
script.js         # 导航、滚动揭示、复制微信号
robots.txt        # 搜索引擎抓取规则
sitemap.xml       # 站点地图
assets/           # 图片资源（webp + 回退）
  og-image.jpg    # 社交分享图（1200×630）
```

## 本地预览

```bash
python3 -m http.server 8080
# 浏览器打开 http://localhost:8080
```

## 部署

线上托管在阿里云 ECS（nginx），站点根目录 `/var/www/horsduroot`。SSH host
`wuhao-tutor-ecs` 走 **2222** 端口（见 `~/.ssh/config`）。两种发布方式：

```bash
# 方式一：从本机用 rsync 同步（推荐）
./deploy.sh

# 方式二：在服务器本机从 GitHub 拉取发布（如本机 SSH 不通时）
#   见 server-deploy.sh，但该脚本仅供服务器端运行，
#   不会被同步进 web 根目录（deploy.sh 与 nginx 均已排除/拒绝）。
```

脚本通过 `rsync` 把站点文件同步到 web 根目录，排除开发文件（`.git`、
`deploy.sh`、`server-deploy.sh`、`assets_orig/`、开发截图等）。
若 rsync 不可用会回退到 `scp`。详见 [deploy.sh](deploy.sh)。

### nginx 行为约定（`/etc/nginx/conf.d/horsduroot.conf`）

- 裸域 `horsduroot.com` 与 HTTP 全部 `301` 跳转到 `https://www.horsduroot.com`（规范化、避免重复内容）。
- 单页静态站：不存在的路径返回真正的 `404`，不回退首页（避免软 404）。
- 静态资源缓存 30 天；`.sh` 与点文件（`/.`）一律拒绝下载。

## 资源优化约定

- 提交前确保新图片已压缩并生成 WebP（`cwebp -q 78 in.jpg -o out.webp`）。
- 大图最长边控制在 1600px 以内；社交图固定 1200×630。
- 原始未压缩素材放在 `assets_orig/`（已被 `.gitignore` 忽略）。
