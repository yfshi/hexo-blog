# FYSBlog

基于 [Astro](https://astro.build) + [Fuwari](https://github.com/saicaca/fuwari) 重构的个人博客，由原来的 Hexo 站点迁移而来。

## 环境要求

- Node.js 20 / 22
- pnpm 9

```shell
npm install -g pnpm@9
```

## 本地开发

```shell
pnpm install
pnpm dev        # 开发预览 http://localhost:4321
pnpm build      # 构建到 dist/（含 pagefind 搜索索引）
pnpm preview    # 预览构建结果
```

## 目录结构

- `src/content/posts/`：文章（Markdown）
- `src/config.ts`：站点信息、导航、个人资料、主题色
- `astro.config.mjs`：站点 URL、base、Markdown/代码高亮等配置
- `public/`：静态资源，按原路径存放（`/img`、`/docs`、`/download`、`CNAME`）

## 新建文章

```shell
pnpm new-post 文章文件名
```

文章 front matter 格式：

```yaml
---
title: "标题"
published: 2024-01-01T00:00:00
description: ""
image: ""
tags: []
category: ""
draft: false
---
```

## 部署

推送到 `master` 分支后，GitHub Actions（`.github/workflows/deploy.yml`）会自动构建并将 `dist/` 发布到 `yfshi/yfshi.github.io` 仓库。

需在仓库 Secrets 中配置 `PERSONAL_TOKEN`（对 `yfshi.github.io` 有写权限的 PAT）。

## 迁移说明

- 原 Hexo 站点保留在 `master` 分支历史中，本次迁移在 `astro` 分支进行。
- 文章由 Hexo 迁移至 `src/content/posts/`，front matter 已转换为 Fuwari 格式：
  - `date` → `published`
  - `categories` → `category`（取第一个）
  - `tags` 统一为数组
- 原图片、文档路径（`/img/...`、`/docs/...`、`/download/...`）保持不变，直接放入 `public/` 即可。
- **URL 变化**：文章地址由 `/yyyy/mm/dd/title/` 变为 `/posts/<文件名>/`。