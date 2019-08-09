---
title: pgbouncer--greenplum测试
date: 2018-07-19 15:53:57
categories: Greenplum
tags:
- PostgreSQL
- pgbouncer
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
  postgres = host=127.0.0.1 dbname=pgbench user=yfshi port=65432
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
  admin_users = yfshi              # 管理员，pgbouncer内部使用
  ```

- userlist.txt

  ```shell
  "admin" "111111"
  "yfshi" "111111"
  ```

## 启动

```shell
$ pgbouncer -d pgbouncer.ini
```

## 管理

> pbouncer提供了类似连接到虚拟数据库pgbouncer,然后执行一些特殊命令的功能,这些命令就像是执行一个真正的SQL命令,让管理者能查询和管理pgbouncer的连接池信息,这个界面为pgbouncer的Console控制界面.一般使用psql命令连接到这个虚拟数据库上.
```shell
$ psql -p6543 pgbouncer
psql (9.6.3, server 1.7.2/bouncer)
Type "help" for help.

pgbouncer=#
```

show help

> NOTICE:  Console usage
> DETAIL:  
> 	SHOW HELP|CONFIG|DATABASES|POOLS|CLIENTS|SERVERS|VERSION
> 	SHOW FDS|SOCKETS|ACTIVE_SOCKETS|LISTS|MEM
> 	SHOW DNS_HOSTS|DNS_ZONES
> 	SHOW STATS|STATS_TOTALS|STATS_AVERAGES
> 	SET key = arg
> 	RELOAD
> 	PAUSE [<db>]
> 	RESUME [<db>]
> 	DISABLE <db>
> 	ENABLE <db>
> 	KILL <db>
> 	SUSPEND
> 	SHUTDOWN
> SHOW

show config

> 显示当前配置设置,一个配置一行,字段如下:
>
> * key：配置变量名称 
> * value：配置值 
> * changeable：yes 或 no,显示这个变量是否可以在运行时修改如果为 no,那么这个变量只能在启动的时候修改

下表是执行show config;的结果。一下的key都可以在pgbouncer.ini的[pgbouncer]中配置：

| key                       | value                                                  | changeable |
| ------------------------- | ------------------------------------------------------ | ---------- |
| job_name                  | pgbouncer                                              | no         |
| conffile                  | pgbouncer.ini                                          | yes        |
| logfile                   | /home/yfshi/pgbouncer/pgbouncer.log                    | yes        |
| pidfile                   | /home/yfshi/pgbouncer/pgbouncer.pid                    | no         |
| listen_addr               | 192.168.2.113                                          | no         |
| listen_port               | 55556                                                  | no         |
| listen_backlog            | 128                                                    | no         |
| unix_socket_dir           | /tmp                                                   | no         |
| unix_socket_mode          | 511                                                    | no         |
| unix_socket_group         |                                                        | no         |
| auth_type                 | trust                                                  | yes        |
| auth_file                 | /home/yfshi/pgbouncer/userlist.txt                     | yes        |
| auth_hba_file             |                                                        | yes        |
| auth_user                 |                                                        | yes        |
| auth_query                | SELECT usename, passwd FROM pg_shadow WHERE usename=$1 | yes        |
| pool_mode                 | session                                                | yes        |
| max_client_conn           | 200                                                    | yes        |
| default_pool_size         | 100                                                    | yes        |
| min_pool_size             | 0                                                      | yes        |
| reserve_pool_size         | 0                                                      | yes        |
| reserve_pool_timeout      | 5                                                      | yes        |
| max_db_connections        | 0                                                      | yes        |
| max_user_connections      | 0                                                      | yes        |
| syslog                    | 0                                                      | yes        |
| syslog_facility           | daemon                                                 | yes        |
| syslog_ident              | pgbouncer                                              | yes        |
| user                      |                                                        | no         |
| autodb_idle_timeout       | 3600                                                   | yes        |
| server_reset_query        | DISCARD ALL                                            | yes        |
| server_reset_query_always | 0                                                      | yes        |
| server_check_query        | select 1                                               | yes        |
| server_check_delay        | 30                                                     | yes        |
| query_timeout             | 0                                                      | yes        |
| query_wait_timeout        | 120                                                    | yes        |
| client_idle_timeout       | 0                                                      | yes        |
| client_login_timeout      | 60                                                     | yes        |
| idle_transaction_timeout  | 0                                                      | yes        |
| server_lifetime           | 3600                                                   | yes        |
| server_idle_timeout       | 600                                                    | yes        |
| server_connect_timeout    | 15                                                     | yes        |
| server_login_retry        | 15                                                     | yes        |
| server_round_robin        | 0                                                      | yes        |
| suspend_timeout           | 10                                                     | yes        |
| ignore_startup_parameters |                                                        | yes        |
| disable_pqexec            | 0                                                      | no         |
| dns_max_ttl               | 15                                                     | yes        |
| dns_nxdomain_ttl          | 15                                                     | yes        |
| dns_zone_check_period     | 0                                                      | yes        |
| max_packet_size           | 2147483647                                             | yes        |
| pkt_buf                   | 4096                                                   | no         |
| sbuf_loopcnt              | 5                                                      | yes        |
| tcp_defer_accept          | 1                                                      | yes        |
| tcp_socket_buffer         | 0                                                      | yes        |
| tcp_keepalive             | 1                                                      | yes        |
| tcp_keepcnt               | 0                                                      | yes        |
| tcp_keepidle              | 0                                                      | yes        |
| tcp_keepintvl             | 0                                                      | yes        |
| verbose                   | 0                                                      | yes        |
| admin_users               | yfshi                                                  | yes        |
| stats_users               |                                                        | yes        |
| stats_period              | 60                                                     | yes        |
| log_connections           | 1                                                      | yes        |
| log_disconnections        | 1                                                      | yes        |
| log_pooler_errors         | 1                                                      | yes        |
| application_name_add_host | 0                                                      | yes        |
| client_tls_sslmode        | disable                                                | no         |
| client_tls_ca_file        |                                                        | no         |
| client_tls_cert_file      |                                                        | no         |
| client_tls_key_file       |                                                        | no         |
| client_tls_protocols      | all                                                    | no         |
| client_tls_ciphers        | fast                                                   | no         |
| client_tls_dheparams      | auto                                                   | no         |
| client_tls_ecdhcurve      | auto                                                   | no         |
| server_tls_sslmode        | disable                                                | no         |
| server_tls_ca_file        |                                                        | no         |
| server_tls_cert_file      |                                                        | no         |
| server_tls_key_file       |                                                        | no         |
| server_tls_protocols      | all                                                    | no         |
| server_tls_ciphers        | HIGH:MEDIUM:+3DES:!aNULL                               | no         |

show pools

> 列出连接池 
>
> * database：数据库名 
> * user：用户名
> * cl_active：当前 active (活跃)的客户端连接的个数
> * cl_waiting：当前 waiting (等待)的客户端连接个数
> * sv_active：当前 active (活跃)的服务器连接个数
> * sv_idle：当前 idle (空闲) 的服务器连接个数
> * sv_used：当前 used (在使用)的服务器连接个数
> * sv_tested：当前 tested (测试过)的服务器连接个数
> * sv_login：当前 login (登录)到 PostgreSQL 服务器的个数
> * maxwait：队列中第一个(最老的那个)客户端等待的时间长度,单位是秒.如果这个数值开始上升,那么就意味着当前的连接池中的服务器处理请求的速度不够快.原因可能是服务器过载,也可能只是 pool_size 太小

show stats

> - database：统计是根据每个数据库分比例的
> - total_requests：连接池处理的SQL请求的总数
> - total_received：接收到的网络流量的总字节数
> - total_sent：发出的网络流量的总字节数
> - total_query_time：活跃在与数据库上面的时间开销总数,单位是微秒
> - avg_req：在最后一次统计过程中的每秒平均请求数
> - avg_recv：每秒(从客户端)接收到的平均数据量
> - avg_sent：每秒发送(给客户端)的平均数据量
> - avg_query：平均的查询时间,单位是微秒

show servers

> 列出数据库与pgbouncer之间连接 
> * type：S,表示服务器 
> * user：gbouncer用于连接服务器的用户名 
> * database：服务器端的数据库名 
> * state：pgbouncer 服务器连接的状态 active、used、idle 
> * addr：PostgreSQL服务器的IP地址 
> * port：PostgreSQL服务器的端口 
> * local_addr：本地机器上的发起连接地址 
> * local_port：本地机器上的发起连接端口 
> * connect_time：连接建立的时间 
> * request_time：请求发出的时间 
> * ptr：这个连接的内部对象地址,用做唯一 ID 
> * link：这个服务器对应的客户端地址

show clients

> 列出客户端及客户端连接状态 
> * type：C,表示客户端 
> * user：客户端连接的用户 
> * database：数据库名 
> * state：客户端连接的状态 active、used、waiting或者idle之一 
> * addr：客户端的 IP 地址 
> * port：客户端连接去的端口 
> * local_addr：本地机器上连接到的对端地址 
> * local_port：本地机器上的连接到的对端端口 
> * connect_time：最后的客户端连接的时间戳 
> * request_time：最后的客户端请求的时间戳 
> * ptr：这个连接的内部对象的地址,用做唯一 ID 
> * link：这个客户端连接对应的服务器的地址

show lists

> 显示连接池的计数信息 
> * databases：数据库的个数 
> * users：用户的个数 
> * pools：连接池的个数 
> * free_clients：空闲客户端的个数 
> * used_clients：已用的客户端的个数 
> * login_clients：处于已登录状态的客户端个数 
> * free_servers：空闲服务器个数 
> * used_servers：已用服务器个数

show databases

> 列出pgbouncer数据库别名及相关数据库 
> * name：已配置的数据库名字记录 
> * host：pgbouncer 连接到的主机名 
> * port：pgbouncer 连接到的端口号 
> * database：pgbouncer 实际连接的数据库名 
> * force_user：当用户是连接字串的一部分的时候,在 pgbouncer 和 PostgreSQL 之间的连接会强制成给出的用户,不管 client user 是什么 
> * pool_size：最大的服务器端连接数目

show fds

> 显示正在使用的 fd 列表如果连接的用户的用户名是 “pgbouncer”,那么通过 unix socket 连接,并且和运行的进程有同样的 UID,实际的 fd 列表是通过这个连接传递的这个机制用于做在线重启 
> - fd：文件描述符的数字值 
> - task：pooler,client 或 server 之一 
> - user：使用该 FD 的连接用户 
> - database：使用该 FD 的连接的数据库 
> - addr：使用该 FD 的连接的 IP 地址,如果使用的是 unix socket,就是 unix 
> - port：使用该 FD 的连接的端口号 
> - cancel：这个连接的取消键字 
> - link：对应的服务器/客户端的 fd如果为 idle (空闲)则为 NULL

DISABLE <db>

> 拒绝指定数据库上所有新客户端连接

ENALBLE <db>

> 准许之前DISABLE命令之后的新客户端连接

PAUSE [<db>]

> 尝试从所有服务器断开连接(等待query完成),在所有query完成之前,此命令不会返回,在数据库重新启动时使用.如果给出了数据库名字则只对该数据库有用

KILL <db>

> 立即删除给定数据库上所有客户端以及数据库连接

SUPEND

> 刷新所有socket缓存,并且停止监听,在缓存flush之前此命令不会有任何返回.使用场景:pgbouncer在线重新启动时使用

RESUME [<db>]

> 从之前PAUSE或者SUPEND命令恢复之前状态

SHUTDOWN

> pgbouncer进程退出

RELOAD

> 重新加载其配置文件并更新配置

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
