---
title: pgbouncer--greenplum测试
date: 2018-07-19 15:53:57
tags: PostgreSQL
---

# 测试环境

系统：CentOS release 6.5 (Final)

节点：

| 节点 | 地址          | 角色                                 |
| ---- | ------------- | ------------------------------------ |
| h1   | 192.168.2.114 | master,seg0~seg7,mirror(seg8~seg15)  |
| h2   | 192.168.2.115 | standby,seg8~seg15,mirror(seg0~seg7) |

连接数：

- pgbouncer --- 100 ---> master
- client --- 1000 ---> pgbouncer

用户：yfshi/123456

# greenplum

## 配置交互key

```shell
# gpssh-exkeys -h h1 -h h2
```

## 安装

略

## 初始化

- 初始化数据目录

  ```shell
  $ gpssh -h h1 -h h2
  => mkdir -p /home/yfshi/gpdata/master
  => mkdir -p /home/yfshi/gpdata/primary
  => mkdir -p /home/yfshi/gpdata/mirror
  ```

- 配置gpinitsystem_config

  ```shell
  ARRAY_NAME="Greenplum Data Platform"
  SEG_PREFIX=gpseg
  PORT_BASE=64300
  declare -a DATA_DIRECTORY=(/home/yfshi/gpdata/primary /home/yfshi/gpdata/primary /home/yfshi/gpdata/primary /home/yfshi/gpdata/primary /home/yfshi/gpdata/primary /home/yfshi/gpdata/primary /home/yfshi/gpdata/primary /home/yfshi/gpdata/primary)
  MASTER_HOSTNAME=h1
  MASTER_DIRECTORY=/home/yfshi/gpdata/master
  MASTER_PORT=65432
  TRUSTED_SHELL=ssh
  CHECK_POINT_SEGMENTS=8
  ENCODING=UNICODE
  
  MIRROR_PORT_BASE=64400
  REPLICATION_PORT_BASE=64500
  MIRROR_REPLICATION_PORT_BASE=64600
  declare -a MIRROR_DATA_DIRECTORY=(/home/yfshi/gpdata/mirror /home/yfshi/gpdata/mirror /home/yfshi/gpdata/mirror /home/yfshi/gpdata/mirror /home/yfshi/gpdata/mirror /home/yfshi/gpdata/mirror /home/yfshi/gpdata/mirror /home/yfshi/gpdata/mirror)
  
  MACHINE_LIST_FILE=/home/yfshi/config/hostfile_gpinitsystem
  ```

- 配置hostfile_gpinitsystem

  ```shell
  h1
  h2
  ```

- 初始化并启动

  ```shell
  $ gpinitsystem -c gpinitsystem_config -s h2
  ```

# pgbouncer测试1000连接数

## 配置

- pgbouncer.ini

  ```shell
  [databases]
  pgbench = host=127.0.0.1 dbname=pgbench user=yfshi port=65432
  [pgbouncer]
  logfile = /home/yfshi/pgbouncer/var/log/pgbouncer.log   # 日志文件
  pidfile = /home/yfshi/pgbouncer/var/log/pgbouncer.pid   # pid文件
  listen_addr = 127.0.0.1          # 监听地址
  listen_port = 6543               # 监听端口
  auth_type = trust
  auth_file = /home/yfshi/pgbouncer/etc/userlist.txt      # 用户认证文件
  pool_mode = session
  server_reset_query = DISCARD ALL
  max_client_conn = 1000           # pgbouncer的客户端最大连接数
  default_pool_size = 100          # 连接池大小
  ```

- userlist.txt

  ```shell
  "yfshi" "111111"
  ```

## 启动

```shell
$ createdb -p65432 pgbench             # 创建pgbench库
$ pgbouncer -d pgbouncer.ini pgbench
```

## 测试

- 只读查询

  ```shell
  $ pgbench -p6543 -i pgbench
  $ pgbench -p6543 -n -S -c 1000 -t 1 pgbench
  transaction type: SELECT only
  scaling factor: 1
  query mode: simple
  number of clients: 1000
  number of threads: 1
  number of transactions per client: 1
  number of transactions actually processed: 1000/1000
  tps = 713.361402 (including connections establishing)
  tps = 866.376950 (excluding connections establishing)
  
  $ psql -p6543 pgbench
  $ SELECT count(*) from pg_stat_activity;
   count 
  -------
     100
  (1 row)
  ```

- 行存插入

  ```shell
  $ psql -p6543 -c "create table table_h(id serial, n1 varchar(20), n2 varchar(20)) distributed by (id);" pgbench;
  $ echo "insert into table_h(n1,n2) values('n1','n2')" > test.sql
  $ pgbench -p6543 -n -f test.sql -c 1000 -t 1 pgbench
  transaction type: Custom query
  scaling factor: 1
  query mode: simple
  number of clients: 1000
  number of threads: 1
  number of transactions per client: 1
  number of transactions actually processed: 1000/1000
  tps = 207.016064 (including connections establishing)
  tps = 217.756804 (excluding connections establishing)
  ```

- 列存插入

  ```shell
  $ psql -p6543 -c "create table table_c(id serial, n1 varchar(20), n2 varchar(20)) with (appendonly=true,orientation=column,compresstype=zlib,COMPRESSLEVEL=5) distributed by (id);" pgbench;
  $ echo "insert into table_c(n1,n2) values('n1','n2')" > test.sql
  $ pgbench -p6543 -n -f test.sql -c 1000 -t 1 pgbench
  transaction type: Custom query
  scaling factor: 1
  query mode: simple
  number of clients: 1000
  number of threads: 1
  number of transactions per client: 1
  number of transactions actually processed: 1000/1000
  tps = 64.295818 (including connections establishing)
  tps = 65.290265 (excluding connections establishing)
  ```