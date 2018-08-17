---
layout: _post
title: GreenPlum编译
date: 2018-07-10 19:34:45
tags:
- PostgreSQL
- GreenPlum
categories: Database
---

操作系统是centos6.4 x64最小安装。



环境搭建方法：

1. 原始方式

   使用官方yum源，如果yum安装的包版本不符合或者不在yum源中，通过源码编译的方式安装。

2. gpdb的README.md的方式

   使用非官方yum源和第三方包管理器配置编译环境，操作更简单，参考README.md。

本文使用的是原始方式。想快速搭建环境，可以选择使用README.md的方式。



# 搭建基本环境

## 添加用户

```shell
$ useradd gpadmin
$ passwd gpadmin
```

把gpadmin加入sudoer，之后的操作都在gpadmin用户下完成。

## 安装工具

```shell
$ sudo yum install -y vim wget zip unzip bzip2 git net-tools sysstat man gcc gcc-c++ make gdb libtool
```

## 安装开发包

```shell
$ sudo yum install -y flex bison zlib-devel readline-devel bzip2-devel openldap-devel libxml2-devel openssl-devel libxslt-devel libevent-devel libcurl-devel perl perl-devel perl-ExtUtils* apr-util-devel apr-devel libyaml-devel json-c-devel c-ares-devel pam-devel libyaml-devel
```

## gcc

greenplum要用到C11/C++11标准，要求gcc版本4.7以上。由于系统自带或yum安装的gcc版本是4.4.7，需要编译更高版本的gcc。

编译gcc需要先编译gmp、mpfr、mpc，按照顺序编译安装。

- gmp

  ```shell
  $ wget https://gmplib.org/download/gmp/gmp-6.1.0.tar.bz2
  $ tar -jxf gmp-6.1.0.tar.bz2
  $ cd gmp-6.1.0
  $ ./configure --prefix=/home/gpadmin/BuildEnv/gcc
  $ make && make install
  ```

- mpfr

  ```shell
  $ wget https://www.mpfr.org/mpfr-3.1.4/mpfr-3.1.4.tar.bz2
  $ tar -jxf mpfr-3.1.4.tar.bz2
  $ cd mpfr-3.1.4
  $ ./configure --prefix=/home/gpadmin/BuildEnv/gcc --with-gmp=/home/gpadmin/BuildEnv/gcc
  make && make install
  ```

- mpc

  ```shell
  $ wget https://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz
  $ tar -zxf mpc-1.0.3.tar.gz
  $ cd mpc-1.0.3
  $ ./configure --prefix=/home/gpadmin/BuildEnv/gcc --with-gmp=/home/gpadmin/BuildEnv/gcc --with-mpfr=/home/gpadmin/BuildEnv/gcc
  $ make && make install
  ```

- gcc

  ```shell
  $ wget ftp://gcc.gnu.org/pub/gcc/releases/gcc-4.8.5/gcc-4.8.5.tar.bz2
  $ tar -jxf gcc-4.8.5.tar.bz2
  $ cd gcc-4.8.5
  $ export LD_LIBRARY_PATH=/home/gpadmin/BuildEnv/gcc/lib:$LD_LIBRARY_PATH
  $ ./configure --prefix=/home/gpadmin/BuildEnv/gcc --with-gmp=/home/gpadmin/BuildEnv/gcc --with-mpfr=/home/gpadmin/BuildEnv/gcc --with-mpc=/home/gpadmin/BuildEnv/gcc
  $ make && make install
  
  $ vi ~/.bashrc
  export LD_LIBRARY_PATH=/home/gpadmin/BuildEnv/gcc/lib:/home/gpadmin/BuildEnv/gcc/lib64:$LD_LIBRARY_PATH
  export PATH=/home/gpadmin/BuildEnv/gcc/bin:$PATH
  $ source ~/.bashrc
  ```

## cmake

gporca要求cmake版本3.1以上，系统自带或者yum安装的cmake是cmake-2.8，需要编译更高版本cmake。

```shell
$ wget https://cmake.org/files/v3.10/cmake-3.10.3.tar.gz
$ tar -zxf cmake-3.10.3.tar.gz
$ cd cmake-3.10.3
$ ./configure --prefix=/home/gpadmin/BuildEnv/cmake
$ make && make install

$ vi ~/.bashrc
export LD_LIBRARY_PATH=/home/gpadmin/BuileEnv/cmake/lib:$LD_LIBRARY_PATH
exprot PATH=/home/gpadmin/BuildEnv/cmake/bin:$PATH
$ source ~/.bashrc
```

## python

greeplum要求python 2.7以上，系统自带或yum安装的python是2.6，需要编译新版本。

- python

  ```shell
  $ wget https://www.python.org/ftp/python/2.7.14/Python-2.7.14.tgz
  $ tar -xf Python-2.7.14.tgz
  $ cd Python-2.7.14
  $ ./configure --prefix=/home/gpadmin/BuildEnv/python --enable-optimizations -enable-shared CFLAGS=-fPIC
  $ make && make install
  
  $ vi ~/.bashrc
  export LD_LIBRARY_PATH=/home/gpadmin/BuileEnv/python/lib:$LD_LIBRARY_PATH
  export PATH=/home/gpadmin/BuildEnv/python/bin:$PATH
  $ source ~/.bashrc
  ```

- pip

  ```shell
  $ python -m ensurepip
  $ pip install --upgrade pip
  ```

- 安装python模块

  ```shell
  $ pip install psutil lockfile paramiko setuptools
  ```

## 安装ninja

```shell
$ wget https://github.com/ninja-build/ninja/releases/download/v1.8.2/ninja-linux.zip
$ mkdir -p /home/gpadmin/BuildEnv/ninja/bin
$ unzip -d /home/gpadmin/BuildEnv/ninja/bin ninja-linux.zip

$ vi ~/.bashrc
$ exprot PATH=/home/gpadmin/BuildEnv/ninja/bin:$PATH
$ source ~/.bashrc
```

# 编译gporca

## gp-xerces

```shell
$ git clone git://github.com/greenplum-db/gp-xerces.git
$ cd gp-xerces/
$ mkdir build
$ cd build
$ ../configure --prefix=/home/gpadmin/gporca
$ make && make install
```

## gporca

```shell
$ git clone git://github.com/greenplum-db/gporca.git
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
$ git clone -b 5X_STABLE git://github.com/greenplum-db/gpdb.git
$ cd gpdb
$ export LIBRARY_PATH=/home/gpadmin/gporca/lib:$LIBRARY_PATH
$ export C_INCLUDE_PATH=/home/gpadmin/gporca/include:$C_INCLUDE_PATH
$ export CPLUS_INCLUDE_PATH=/home/gpadmin/gporca/include:$CPLUS_INCLUDE_PATH
$ ./configure --with-perl --with-python --with-libxml --with-gssapi --prefix=/home/gpadmin/gpdb
$ make && make install
```

# 编译postgis

## geos

```shell
$ wget http://download.osgeo.org/geos/geos-3.4.2.tar.bz2
$ tar xjf geos-3.4.2.tar.bz2
$ cd geos-3.4.2
$ ./configure --prefix=/home/yuzhang/opt/geos
$ make && make install
```

## proj

```shell
$ wget http://download.osgeo.org/proj/proj-4.9.1.tar.gz
$ tar xzf proj-4.9.1.tar.gz
$ cd proj-4.9.1
$ ./configure --prefix=/home/yuzhang/opt/proj
$ make && make install
```

## gdal

```shell
$ wget http://download.osgeo.org/gdal/1.11.2/gdal-1.11.2.tar.gz
$ tar xzf gdal-1.11.2.tar.gz
$ cd gdal-1.11.2
$ ./configure --prefix=/home/yuzhang/opt/gdal
$ make && make install

$ vi ~/.bashrc
export LD_LIBRARY_PATH=/home/gpadmin/BuildEnv/geos/lib:/home/gpadmin/BuildEnv/proj/lib:/home/pgadmin/BuildEnv/gdal/lib:$LD_LIBRARY_PATH
$ source ~/.bashrc
```

## postgis

```shell
$ git clone git://github.com/greenplum-db/geospatial.git
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

pgbouncer要求libevent 2.0以上，系统自带或yum安装的libevent是1.4，需要编译新版本

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

## pgbouncer

```shell
$git clone -b pgbouncer_1_8_1 git://github.com/greenplum-db/pgbouncer.git
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

## jdk

```shell
$ sudo yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
```

## Apache Maven

```shell
$ wget http://mirrors.hust.edu.cn/apache/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz
$ tar -zxf apache-maven-3.5.3-bin.tar.gz -C /home/gpadmin/BuildEnv/
$ mv /home/gpadmin/BuildEnv/apache-maven-3.5.3 /home/gpadmin/BuildEnv/apache-maven

$ vi ~/.bashrc
export PATH=/home/gpadmin/BuildEnv/apache-maven/bin:$PATH
$ souce ~/.bashrc
```

## jdbc

```shell
$ wget https://jdbc.postgresql.org/download/postgresql-jdbc-42.2.2.src.tar.gz --no-check-certificate
$ tar -zxf postgresql-jdbc-42.2.2.src.tar.gz
$ cd postgresql-jdbc-42.2-2.src/pgjdbc/
$ mvn package –DskipTests
$ cp target/postgresql-42.2.2.jar /home/gpadmin/gpdb/lib
```

# 编译odbc

## unixodbc

```shell
$ sudo yum install -y unixODBC-devel
```

## odbc

```shell
$ wget https://ftp.postgresql.org/pub/odbc/versions/src/psqlodbc-09.03.0400.tar.gz --no-check-certificate
$ tar -xf psqlodbc-09.03.0400.tar.gz
$ cd psqlodbc-09.03.0400
$ ./configure --prefix=/home/gpadmin/psqlodbc
$ make && make install
```

## 测试

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

