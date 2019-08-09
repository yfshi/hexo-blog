---
layout: _post
title: ao表
date: 2019-08-09 14:19:12
categories: Greenplum
tags:
- appendonly
- appendoptimized
- Greenplum
---

ao表，即append only表，顾名思义，只能追加。后来支持了删除和更新，ao表演进为append optimized表。本文以greenplum6为基础。

# 用法

创建行存ao表：`create table test(id int, name varchar*64) with (appendoptimized=true);`

创建列存ao表：`create table test1(id int, name varchar*64) with (appendoptimized=true, orientation=column);`

# 涉及的表

* pg_class

  系统表，记录表的元信息。

* pg_appendonly

  系统表，记录ao表特有的元信息。

* pg_fastsequence。

  系统表，记录ao表的当前行号，每插入一行，行号递增。

* pg_aoseg.pg_aoseg_xxxx

  普通表，每个ao表对应一个aoseg表，记录ao表每个文件的信息，如块数量、元组数量等。

* pg_aoseg.pg_aovisimap_xxxx

  普通表，每个ao表对应一个visimap表，记录ao元组的可见性。只有删除和更新时设置对应的visimap位置。

* pg_aoseg.pg_aoblkdir_xxxx

  普通表，如果ao表有索引，则每个ao表对应一个块目录表。列存表每一列对应一个块目录表。

# ....