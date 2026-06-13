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

线上托管在阿里云 ECS（nginx），站点根目录由 nginx `root` 指向。
使用仓库自带脚本同步发布（需在白名单网络内、且本地配置好 SSH host `wuhao-tutor-ecs`）：

```bash
./deploy.sh
```

脚本通过 `rsync` 把站点文件同步到服务器 web 根目录，排除开发文件。
若 rsync 不可用会回退到 `scp`。详见 [deploy.sh](deploy.sh)。

## 资源优化约定

- 提交前确保新图片已压缩并生成 WebP（`cwebp -q 78 in.jpg -o out.webp`）。
- 大图最长边控制在 1600px 以内；社交图固定 1200×630。
- 原始未压缩素材放在 `assets_orig/`（已被 `.gitignore` 忽略）。
