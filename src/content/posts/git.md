---
title: "git"
published: 2018-07-31T15:22:54
description: ""
image: ""
tags: ["git"]
category: "常用工具"
draft: false
---

官方文档：
[progit_v2.1.15.pdf](/docs/progit_v2.1.15.pdf)
来自：
[https://git-scm.com/book/zh/v2](https://git-scm.com/book/zh/v2)



# 完整迁移

把本地git库localtest完整的迁移到github上的test库，保留提交记录:

```shell
# github端建立test空白库

# 本地库镜像推送
$ cd localtest
# git push --mirror git@github.com:yfshi/test.git
```

