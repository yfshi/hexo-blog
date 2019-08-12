---
layout: _post
title: ao表的唯一约束
date: 2019-08-09 14:19:12
categories: Greenplum
tags:
- appendonly
- appendoptimized
- Greenplum
---

> 本文基于greenplum6.beta4。

greenplun的ao表不支持唯一约束，创建唯一约束（unique index或primary）会报错。

```shell
postgres# create table test(id int) with (appendoptimized=true);
NOTICE:  Table doesn't have 'DISTRIBUTED BY' clause -- Using column named 'id' as the Greenplum Database data distribution key for this table.
HINT:  The 'DISTRIBUTED BY' clause determines the distribution of data. Make sure column(s) chosen are the optimal data distribution key to minimize skew.
CREATE TABLE
postgres=# create unique index test_index on test(id);
ERROR:  append-only tables do not support unique indexes
```

heap表和ao表的索引区别：

- heap表可以通过索引直接找到元组，heap的表索引格式“{key, ctid}”，ctid即元组地址，heap表可以直接判断元组的可见性。
- ao表不能通过索引直接找到元组，ao的索引格式类似“{key, {segno,groupno,rowno}}”，通过key找到索引项，在pg_aoseg.pg_aoblkdir_xxx表查找索引项，找到对应的块位置，然后读取文件块，最后根据行号找到块内元组。

由上述描述可知，ao表比heap多了一个辅助文件pg_aoseg.pg_aoblkdir_xxx，该文件记录ao表块地址和行号。ao表的块写满和插入结束时才会更新pg_aoseg.pg_aoblkdir_xxx，因此对于正在写入的块，无法看到已经写入的元组，即无法判断唯一性。

ao表单独插入一行数据，会占用一个块，批量写入数据，如果块剩余空间足够则继续往块内追加数据，所以ao表适合批量写入。

# 分析

在代码中查找报错位置，比较明显。在索引创建函数DefineIndex()内，如果主表是ao表，则报错。如下：

```c
Oid
DefineIndex()
{
	...

    if  (stmt->unique && RelationIsAppendOptimized(rel))
        ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                 errmsg("append-only tables do not support unique indexes")));

    ...
}
```

那么，单独将此处的限制放开是否能支持唯一约束？答案是否定的，如果是每次都是插入一行数据，可能没问题；但是批量插入，则无法判断该批次内的唯一性，因为当前批次已经插入的数据不可见。

ao唯一性判断接口是存在的（猜测：greenplum想要实现唯一约束？但是由于某些问题未解决？）：`_bt_ao_check_unique <-- _bt_check_unique <-- _bt_doinsert <-- btinsert`

# 思路

- 放开对ao表唯一索引的限制
- 判断唯一性时添加当前正在插入的块的判断
- 其他可能存在的问题

