---
layout: _post
title: Makefile
date: 2018-10-30 10:01:54
categories: Makefile
tags: Makefile
---
下面是一个基础的Makefile文件

```makefile
# 一些基本命令和参数
CC = gcc
AR = ar
AROPT = crs
CFLAGS += -g3 -O0
CFLAGS += -std=gnu99 -Wall
CFLAGS += -I./include -fPIC
CFLAGS += -fpic

# 编译命令，编译.o、.a、.so的命令分别如下：
COMPILER = $(CC) $(CFLGAS)
LINK.static = $(AR) $(AROPT)
LINK.shared = $(COMPILER) -shared #-Wl,-soname,xxx

# 编译过程需要链接的库，-Wl,--as-needed告诉连接器按需链接，比如crypto有的目标没有引用，则不连接
LDFLAGS += -L./lib -Wl,--as-needed
LIBS += -ltest -lcrypto -ld -lz -lc

# 公用接口文件
OBJS :=  common.o

# 要生成的目标文件
PROGS := dgcheck dgservice libdongle.so libdongle.a test

all: $(PROGS)

dgcheck: dgcheck.o libdongle.o $(OBJS)
	$(COMPILER) $^ $(LDFLAGS) $(LIBS) -o $@

dgservice: dgservice.o dongle.o $(OBJS)
	$(COMPILER) $^ $(LDFLAGS) $(LIBS) -o $@

libdongle.so: libdongle.o $(OBJS)
	$(LINK.shared) $^ $(LDFLAGS) $(LIBS) -o $@

libdongle.a: libdongle.o $(OBJS)
	$(LINK.static) $@ $^ 

test: test.o libdongle.o $(OBJS)
	$(COMPILER) $^ $(LDFLAGS) $(LIBS) -o $@

clean:
rm -f *.o $(PROGS)

install: $(PROGS)
	mkdir -p deploy
	cp -f $^ deploy

uninstall:
	rm -rf deploy
```
