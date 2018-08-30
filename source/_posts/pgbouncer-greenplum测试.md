---
title: pgbouncer--greenplum测试
date: 2018-07-19 15:53:57
tags:
- PostgreSQL
- pgbouncer
categories: Database
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

下面列出一些pgbouncer配置项


| 配置项                    | 解释                                                         |
| ------------------------- | ------------------------------------------------------------ |
| logfile                   | 指定日志文件                                                 |
| pidfile                   | 指定pidfile,文件中记录了pgbouncer的进程ID,如果是加-d启动则此项是必须配置,如果未配置启动报错 |
| listen_addr               | 监听的IP地址                                                 |
| listen_addr               | 监听的IP端口                                                 |
| unix_socket_dir           | 指定unix socket的文件目录,默认是/tmp                         |
| unix_socket_mode          | 指定unix socket文件属性,默认 0777                            |
| unix_socket_group         | 指定unix socket文件的组,默认没有设置                         |
| auth_file                 | 指定连接pgbouncer的用户名和密码认证文件                      |
| auth_type                 | 认证方法,可设置为any, trust, plain, crypt, md5               |
| pool_mode                 | 连接池模式,可为session, transaction, statement               |
| max_client_conn           | 准许连接到pgbouncer上最大客户端数                            |
| default_pool_size         | 连接池与数据库默认大小,不同的用户或者数据库会有不同的连接池  |
| min_pool_size             | 连接池最小大小,即每个连接池和数据库保持的连接数              |
| reserve_pool_size         | 连接池保留连接数                                             |
| reserve_pool_timeout      | 保留连接的超时时间                                           |
| server_round_robin        | 负载均衡模式是否为 round robin,默认是关闭,采用LIFO(后进先出) |
| ignore_startup_parameters | 默认pgbouncer会跟踪一些数据库参数,如client_encoding,datestyle,timezone,standard_conforming_strings,application_name等,pgbouncer能检车出这几个参数的变化并与客户端保持一致,所以默认情况下设置其他参数会导致pgbouncer抛出错误.设置此项,指定一些数据库参数,pgbouncer就可以忽略对这些参数的检查,不同参数之间用逗号隔开 |
| disable_pqexec            | 是否禁止简单查询协议,默认是为0禁止.简单查询协议准许一个请求发送多条SQL,容易导致SQL注入攻击 |
| syslog                    | 是否打开syslog,window下没有syslog,则使用eventlog.默认为0,表示不打开 |
| syslog_facility           | 可配置为auth, authpriv, daemon, user, local0-7默认是daemon   |
| syslog_ident              | 以什么名称发送日志到syslog,默认是pgbouncer                   |
| log_connections           | 是否记录连接成功的日志,默认值是1,记录                        |
| log_disconnections        | 是否记录断开连接的日志, 默认值是1,记录                       |
| log_pooler_errors         | 连接池发往客户端的错误是否记录在日志中,默认值是1,记录        |
| stats_period              | 将汇总的统计信息写入日志的时间周期,默认60                    |
| verbose                   | 日志记录的详细程度,在启动命令行中 –v –v 与verbose=2是同样的含义 |
| admin_users               | 准许在console端执行一些管理命令的用户列表,多个用户之间以逗号隔开.当设置auth_mod=any时,此配置可忽略,默认为空. |
| stats_users               | 准许连接到console上查看连接池只读信息的用户列表.这些用户可以执行除show fds命令之外的其他show命令. |
| server_reset_query        | 当一个后端数据库连接会话被某一个客户端使用时,它的属性可能会改变,所以当这个后端数据端连接呗第二个客户端使用时,就可能会产生问题.因此一个连接被使用后重新放回连接池时,需要对这个连接的属性进行复位.默认设置为DISCARD ALL.需要注意在连接池为事务模式是,此配置项应该为空,因为在事务模式下,客户端不应该设置连接会话的属性 |
| server_check_delay        | 空闲连接需要多长时间进行一次健康检查,查看其是否可用.如果设置为0则立即检查,默认设置为30s |
| server_check_query        | 健康检查的SQL,如果为空则禁止健康检查.默认为SELECT 1          |
| server_lifetime           | 连接存活时间.当一个连接存活时间超过此值时,就会被关闭,然后新建一个连接.默认为3600s,模板配置文件中是1200s与默认值有冲突.如果设置为0,表示此连接只是用一次,使用后就关闭 |
| server_idle_timeout       | 连接池中连接的idle时间,超过此时间,连接会被关闭,默认值为600s  |
| server_connect_timeout    | 到后端数据库的login时间超过此值后,连接就会被关闭.默认为15s   |
| server_login_retry        | 指定创建到后端数据库连接失败后,等待多长时间重试,默认值为15s  |
| client_login_timeout      | 客户端与pgbouncer建立连接后,如果无法再这段时间内完成登录,那么连接将会被断开.默认为60s |
| autodb_idle_timeout       | 如果自动创建的数据库池已经使用用了这个时间值,那么他们会被释放,不好的方面是响应的统计数据也会丢掉,默认3600s |
| suspend_timeout           | 在SUSPEND命令暂停或者用-R重新启动期间等待缓冲区刷新的秒数,如果在此时间内flush不成功，连接将被丢弃 |
| query_timeout             | 运行时间超过该时间值的SQL会被终止.此值应该设置得比SQL的实际运行时间长一些,也应该比数据库的statement_timeout参数配置的值大一些.这个参数主要是为了便于应付一些未知网络问题.设置此值可防止查询被长时间hang住.默认值为0,表示禁止此功能  测试:设置query_timeout=1,在客户端运行超过1s的SQL报错如下 |
| query_wait_timeout        | 一个请求在队列中等待被执行的最长时间,如果超过此时间还没有被分配到连接,则此客户端连接将会被断开.这主要为了防止数据库hang住后,客户端到pgbouncer的连接也一直被hang住,默认值为120s,如果设置为0则客户端无线排队等待 |
| client_idle_timeout       | 如果客户端空闲该时间值后,一直不发送命令,则断开与此客户端的连接.这一般是为了防止客户端上的TCP连接实际上因为网络问题关闭,但是pgbouncer上相应的连接没有检测到客户端已经不存在而一直存在.默认值为0,表示禁止此功能 |
| idle_transaction_timeout  | 客户端启动事务后,超过此时间值还不提交事务,则关闭这个客户端连接,防止客户端消耗pgbouncer及数据库的资源,默认为0,表示禁止此功能 |
| pkt_buf                   | 用于指定网络包的内部缓冲区大小,该值会影响发出的TCP包大小即内存使用大小.实际的libpq数据包可以比这个大,所以没有必要设置的太大.默认值为4096,一般保值这个值即可 |
| max_packet_size           | 通过pgbouncer的最大包大小,这个包可以是一个SQL,也可以是一个SQL的返回结果集,有可能这个结果集非常大.默认为2147483647 |
| listen_backlog            | TCP监听函数listen的Backlog参数,默认是128,通过man 2 listen可查看backlog的含义  backlog参数定义sockfd的挂起连接队列可能增长的最大长度。如果在队列已满时连接请求到达，则客户端可能会收到带有ECONNREFUSED指示的错误，或者如果底层协议支持重传，则可能会忽略该请求，以便连接中的后续重新尝试成功 |
| sbuf_loopcnt              | 在处理过程中,每个连接处理多少数据后切换到下一个连接.如果没有这个限制那么有可能会出现一个连接发送或者接收大量数据时,可能会导致其他连接饿死.如果设置为0表示不限制.默认值是5 |
| tcp_defer_accept          | 此选项值的详细说明从linux下 man 7 tcp中获取.在linux下次默认值为45,其他平台为0 |
| tcp_socket_buffer         | 默认未设置                                                   |
| tcp_keepalive             | 是否以操作系统的默认值打开基本的keepalive设置.在linux操作系统下探活的相关默认设置为net.ipv4.tcp_keepalive_time = 7200, net.ipv4.tcp_keepalive_intvl = 75, net.ipv4.tcp_keepalive_probes = 9这些值默认偏大,一般根据实际情况调整 |
| tcp_keepcnt               | 默认未设置                                                   |
| tcp_keepidle              | 默认未设置                                                   |
| tcp_keepintvl             | 默认未设置                                                   |

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
