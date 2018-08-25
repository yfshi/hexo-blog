---
layout: _post
title: Greenplum编译
date: 2018-07-10 19:34:45
tags:
- PostgreSQL
- Greenplum
categories: Database
---

> 操作系统：centos6.4 x64最小安装

# 添加用户

```shell
$ useradd gpadmin
$ passwd gpadmin
```

把gpadmin加入sudoer，之后的操作都在gpadmin用户下完成。

# 搭建开发环境

```shell
# linux基本环境
$ sudo yum install -y bzip2 cmake gcc gcc-c++ gdb git libtool lrzsz make man net-tools sysstat unzip vim wget zip

# 数据库开发环境
$ sudo yum install -y apr-devel apr-util-devel bison bzip2-devel c-ares-devel flex java-1.8.0-openjdk java-1.8.0-openjdk-devel json-c-devel krb5-devel libcurl-devel libevent-devel libkadm5 libxml2-devel libxslt-devel libyaml-devel openldap-devel openssl-devel pam-devel perl perl-devel perl-ExtUtils-Embed readline-devel unixODBC-devel zlib-devel
```

一般来说，上面安装的开发包足够一般的数据库编译或安装使用了。

> 如果Greenplum版本较新(>=5X_STABLE)，CentOS 6.4官方的开发包版本可能无法满足Greenplum（比如glibc不支持C11标准，python版本较低、cmake版本较低等）,也可能会缺少一些其他的包。
>
> 可以通过源码编译或者非官方yum源安装合适的版本。

# 编译开发包

## gcc-4.8.5

Greenplum较新的代码要用到C11/C++11标准，要求gcc版本4.7以上。由于系统自带或yum安装的gcc版本是4.4.7，需要编译更高版本的gcc。

编译gcc需要先编译gmp、mpfr、mpc，按照顺序编译安装。

```shell
# 编译gmp
$ wget https://gmplib.org/download/gmp/gmp-6.1.0.tar.bz2
$ tar -jxf gmp-6.1.0.tar.bz2
$ cd gmp-6.1.0
$ ./configure --prefix=/home/gpadmin/BuildEnv/gcc
$ make && make install

# 编译mpfr
$ wget https://www.mpfr.org/mpfr-3.1.4/mpfr-3.1.4.tar.bz2
$ tar -jxf mpfr-3.1.4.tar.bz2
$ cd mpfr-3.1.4
$ ./configure --prefix=/home/gpadmin/BuildEnv/gcc --with-gmp=/home/gpadmin/BuildEnv/gcc
make && make install

# 编译mpc
$ wget https://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz
$ tar -zxf mpc-1.0.3.tar.gz
$ cd mpc-1.0.3
$ ./configure --prefix=/home/gpadmin/BuildEnv/gcc --with-gmp=/home/gpadmin/BuildEnv/gcc --with-mpfr=/home/gpadmin/BuildEnv/gcc
$ make && make install

# 编译gcc
$ wget ftp://gcc.gnu.org/pub/gcc/releases/gcc-4.8.5/gcc-4.8.5.tar.bz2
$ tar -jxf gcc-4.8.5.tar.bz2
$ cd gcc-4.8.5
$ export LD_LIBRARY_PATH=/home/gpadmin/BuildEnv/gcc/lib:$LD_LIBRARY_PATH
$ ./configure --prefix=/home/gpadmin/BuildEnv/gcc --with-gmp=/home/gpadmin/BuildEnv/gcc --with-mpfr=/home/gpadmin/BuildEnv/gcc --with-mpc=/home/gpadmin/BuildEnv/gcc --disable-multilib
$ make && make install

# 设置环境变量
$ vi ~/.bashrc
export LD_LIBRARY_PATH=/home/gpadmin/BuildEnv/gcc/lib:/home/gpadmin/BuildEnv/gcc/lib64:$LD_LIBRARY_PATH
export PATH=/home/gpadmin/BuildEnv/gcc/bin:$PATH
$ source ~/.bashrc
```

## cmake3

gporca要求cmake版本3.1以上，系统自带或者yum安装的cmake是cmake-2.8，需要编译更高版本cmake。

```shell
$ wget https://cmake.org/files/v3.10/cmake-3.10.3.tar.gz
$ tar -zxf cmake-3.10.3.tar.gz
$ cd cmake-3.10.3
$ ./configure --prefix=/home/gpadmin/BuildEnv/cmake
$ make && make install

$ vi ~/.bashrc
export LD_LIBRARY_PATH=/home/gpadmin/BuileEnv/cmake/lib:$LD_LIBRARY_PATH
export PATH=/home/gpadmin/BuildEnv/cmake/bin:$PATH
$ source ~/.bashrc
```

## python-2.7

greeplum要求python 2.7以上，系统自带或yum安装的python是2.6，需要编译新版本。

```shell
# 编译python
$ wget https://www.python.org/ftp/python/2.7.14/Python-2.7.14.tgz
$ tar -xf Python-2.7.14.tgz
$ cd Python-2.7.14
$ ./configure --prefix=/home/gpadmin/BuildEnv/python --enable-optimizations -enable-shared CFLAGS=-fPIC
$ make && make install

# 设置环境变量
$ vi ~/.bashrc
export LD_LIBRARY_PATH=/home/gpadmin/BuildEnv/python/lib:$LD_LIBRARY_PATH
export PATH=/home/gpadmin/BuildEnv/python/bin:$PATH
$ source ~/.bashrc

# 安装pip
$ python -m ensurepip
$ pip install --upgrade pip

# 安装python模块
$ pip install psutil lockfile paramiko setuptools
```

## ninja

```shell
$ wget https://github.com/ninja-build/ninja/releases/download/v1.8.2/ninja-linux.zip
$ mkdir -p /home/gpadmin/BuildEnv/ninja/bin
$ unzip -d /home/gpadmin/BuildEnv/ninja/bin ninja-linux.zip

$ vi ~/.bashrc
$ export PATH=/home/gpadmin/BuildEnv/ninja/bin:$PATH
$ source ~/.bashrc
```

## geos+proj+gdal

```shell
# geos
$ wget http://download.osgeo.org/geos/geos-3.4.2.tar.bz2
$ tar xjf geos-3.4.2.tar.bz2
$ cd geos-3.4.2
$ ./configure --prefix=/home/gpadmin/BuildEnv/geos
$ make && make install

# proj
$ wget http://download.osgeo.org/proj/proj-4.9.1.tar.gz
$ tar xzf proj-4.9.1.tar.gz
$ cd proj-4.9.1
$ ./configure --prefix=/home/gpadmin/BuildEnv/proj
$ make && make install

# gdal
$ wget http://download.osgeo.org/gdal/1.11.2/gdal-1.11.2.tar.gz
$ tar xzf gdal-1.11.2.tar.gz
$ cd gdal-1.11.2
$ ./configure --prefix=/home/gpadmin/BuildEnv/gdal
$ make && make install

# 设置环境变量
$ vi ~/.bashrc
export LD_LIBRARY_PATH=/home/gpadmin/BuildEnv/geos/lib:/home/gpadmin/BuildEnv/proj/lib:/home/gpadmin/BuildEnv/gdal/lib:$LD_LIBRARY_PATH
export PATH=/home/gpadmin/BuildEnv/geos/bin:/home/gpadmin/BuildEnv/proj/bin:/home/gpadmin/BuildEnv/gdal/bin:$PATH
$ source ~/.bashrc
```

## libevent

```shell
$ wget https://github.com/downloads/libevent/libevent/libevent-2.0.20-stable.tar.gz
$ tar xf libevent-2.0.20-stable.tar.gz
$ cd libevent-2.0.20-stable
$ ./configure --prefix=/home/gpadmin/BuildEnv/libevent
$ make && make install

$ vi ~/.bashrc
export LD_LIBRARY_PATH=/home/gpadmin/BuildEnv/libevent/lib:$LD_LIBRARY_PATH
export PATH=/home/gpadmin/BuildEnv/libevent/bin:$PATH
$ source ~/.bashrc
```

## Apache Maven

```shell
$ wget http://mirrors.hust.edu.cn/apache/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz
$ tar -zxf apache-maven-3.5.4-bin.tar.gz -C /home/gpadmin/BuildEnv/
$ mv /home/gpadmin/BuildEnv/apache-maven-3.5.4 /home/gpadmin/BuildEnv/apache-maven

$ vi ~/.bashrc
export PATH=/home/gpadmin/BuildEnv/apache-maven/bin:$PATH
$ souce ~/.bashrc
```

# 编译gporca

```shell
# gp-xerces
$ git clone git://github.com/Greenplum-db/gp-xerces.git
$ cd gp-xerces/
$ mkdir build
$ cd build
$ ../configure --prefix=/home/gpadmin/gporca
$ make && make install

# gporca
$ git clone git://github.com/Greenplum-db/gporca.git
$ cd gporca
$ cmake -GNinja -D CMAKE_INSTALL_PREFIX=/home/gpadmin/gporca -D XERCES_LIBRARY=/home/gpadmin/gporca/lib/libxerces-c.so -D XERCES_INCLUDE_DIR=/home/gpadmin/gporca/include -H. -Bbuild
$ ninja install -C build

$ vi ~/.bashrc
export LD_LIBRARY_PATH=/home/gpadmin/gporca/lib:$LD_LIBRARY_PATH
export PATH=/home/gpadmin/gporca/bin:$PATH
$ source ~/.bashrc
```

# 编译gpdb

```shell
$ git clone git://github.com/Greenplum-db/gpdb.git
$ cd gpdb
$ export LIBRARY_PATH=/home/gpadmin/gporca/lib:$LIBRARY_PATH
$ export C_INCLUDE_PATH=/home/gpadmin/gporca/include:$C_INCLUDE_PATH
$ export CPLUS_INCLUDE_PATH=/home/gpadmin/gporca/include:$CPLUS_INCLUDE_PATH
$ ./configure --with-perl --with-python --with-libxml --with-gssapi --prefix=/home/gpadmin/gpdb
$ make && make install
```

# 编译postgis

> PostGIS 2.1.5 for GreenPlum 5.x+ 

```shell
$ git clone git://github.com/Greenplum-db/geospatial.git
$ source /home/gpadmin/gpdb/greenplum_path.sh
$ cd geospatial/postgis/build/postgis-2.1.5/
$ ./configure --prefix=$GPHOME --with-pgconfig=$GPHOME/bin/pg_config --with-raster --without-topology --with-projdir=/home/gpadmin/BuildEnv/proj
$ make USE_PGXS=1 clean all install

# 安装postgis
$ psql -d postgres -f ${GPHOME}/share/postgresql/contrib/postgis-2.1/postgis.sql
$ psql -d postgres -f ${GPHOME}/share/postgresql/contrib/postgis-2.1/postgis_comments.sql
$ psql -d postgres -f ${GPHOME}/share/postgresql/contrib/postgis-2.1/rtpostgis.sql
$ psql -d postgres -f ${GPHOME}/share/postgresql/contrib/postgis-2.1/raster_comments.sql
$ psql -d postgres -f ${GPHOME}/share/postgresql/contrib/postgis-2.1/spatial_ref_sys.sql

$ vi $GPHOME/greenplum_path.sh
export GDAL_DATA=$GPHOME/share/gdal
export POSTGIS_ENABLE_OUTDB_RASTERS=0
export POSTGIS_GDAL_ENABLED_DRIVERS=DISABLE_ALL

$ gpstop –r	//重启数据库
```

# 编译pgbouncer

```shell
$ git clone -b pgbouncer_1_8_1 git://github.com/Greenplum-db/pgbouncer.git
$ cd pgbouncer
$ git submodule init
$ git submodule update
$ ./autogen.sh
$ ./configure --prefix=/home/gpadmin/pgbouncer
$ make && make install

$ vi ~/.bashrc
export PATH=/home/gpadmin/pgbouncer/bin:$PATH
$ source ~/.bashrc
```

# 编译jdbc

```shell
$ wget https://jdbc.postgresql.org/download/postgresql-jdbc-42.2.2.src.tar.gz --no-check-certificate
$ tar -zxf postgresql-jdbc-42.2.2.src.tar.gz
$ cd postgresql-jdbc-42.2-2.src/pgjdbc/
$ mvn package –DskipTests
$ cp target/postgresql-42.2.2.jar /home/gpadmin/gpdb/lib
```

# 编译odbc

```shell
$ wget https://ftp.postgresql.org/pub/odbc/versions/src/psqlodbc-09.03.0400.tar.gz --no-check-certificate
$ tar -xf psqlodbc-09.03.0400.tar.gz
$ cd psqlodbc-09.03.0400
$ ./configure --prefix=/home/gpadmin/psqlodbc
$ make && make install
```

测试：

```shell
$ sudo vi /etc/odbcinst.ini
[PostgreSQL]
Description   = ODBC for PostgreSQL
Driver       = /home/gpadmin/psqlodbc/lib/psqlodbcw.so 
Setup       = /usr/lib/libodbcpsqlS.so
Driver64     = /home/gpadmin/psqlodbc/lib/psqlodbcw.so 
Setup64     = /usr/lib64/libodbcpsqlS.so
FileUsage	    = 1

$ vi ~/.odbc.ini
[gp]
Description = Test to gp
Driver = PostgreSQL
Database = postgres
Servername = 127.0.0.1
UserName = gpadmin
Password = 111111
Port = 5432
ReadOnly = 0

$ source /home/gpadmin/gpdb/greenplum_path.sh
$ isql gp
```

# 附：CentOS 7.0编译gpdb

> CentOS 7.0最小化安装

系统设置：

```shell
# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# 关闭selinux
setenforce 0
vi /etc/selinux/config
SELINUX=disabled

# 配置ip，网络等

# 安装基本环境
yum install -y bzip2 git lrzsz sysstat unzip vim wget zip

# 添加用户
$ useadd gpadmin
$ passwd gpadmin
$ su - gpadmin

# 下载代码
$ mkdir /home/gpadmin/code
$ cd /home/gpadmin/code
$ git clone https://github.com/greenplum-db/gpdb.git

# 安装开发环境
$ sudo ln -sf /bin/cmake3 /usr/local/bin/cmake
$ cd /home/gpadmin/code/gpdb
$ ./README.CentOS.bash

# 系统配置
$ sudo bash -c 'cat >> /etc/sysctl.conf <<-EOF
kernel.shmmax = 500000000
kernel.shmmni = 4096
kernel.shmall = 4000000000
kernel.sem = 500 1024000 200 4096
kernel.sysrq = 1
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.msgmni = 2048
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.conf.all.arp_filter = 1
net.ipv4.ip_local_port_range = 1025 65535
net.core.netdev_max_backlog = 10000
net.core.rmem_max = 2097152
net.core.wmem_max = 2097152
vm.overcommit_memory = 2

EOF'

$ sudo bash -c 'cat >> /etc/security/limits.conf <<-EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 131072
* hard nproc 131072

EOF'

$ sudo bash -c 'cat >> /etc/ld.so.conf <<-EOF
/usr/local/lib

EOF'

# 编译gporca
$ cd /home/gpadmin/code/gpdb/depends
$ ./configure --prefix=/home/gpadmin/gpdb
$ make && make install

# 编译gpdb
$ LD_LIBRARY_PATH=/home/gpadmin/gpdb/lib ./configure \
--with-libraries=/home/gpadmin/gpdb/lib \
--with-includes=/home/gpadmin/gpdb/include \
--with-perl --with-python --with-libxml --with-gssapi --prefix=/home/gpadmin/gpdb
$ LD_LIBRARY_PATH=/home/gpadmin/gpdb/lib make install
```
