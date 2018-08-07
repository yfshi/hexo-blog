---
layout: _post
title: PostgreSQL内存上下文
date: 2018-01-11 15:05:42
tags:
- PostgreSQL
- 内存管理
categories: Database
---

# 内存管理体系结构

![](/img/内存管理体系结构.png)

---

# 内存上下文

内存上下文（MemoryContext）借鉴了操作系统的一些概念。

操作系统为每个进程分配了进程执行环境，进程之间互不影响，由操作系统来对环境进行切换，进程可以在其进程环境中调用内存操作函数：malloc、free、realloc等。

类似的，一个内存上下文实际上相当于一个进程环境，PostgreSQL以类似的方式提供了在内存上下文进行内存操作的函数：palloc、pfree、repalloc等。

每个进程/线程有多个私有的内存上下文，组成上下文树。

---

# 内存上下文树

![内存上下文](/img/内存上下文.jpg)

- 每个线程都有多个内存上上下文，组成树形结构。线程所有的内存操作都在各种语义的上下文中进行。
- 释放上下文节点会释放其所有的子节点。
- 线程退出时释放TopMemoryContext。

---

# 术语

- MemoryContext
- AllocSetContext
- Block
- Chunk
- 超大块
- Chunk Free List

---

# 内存上下文结构

![](/img/内存上下文存储结构.jpg)

---

# 数据结构
- MemoryContext
- MemoryContextMethods
- AllocSet
- AllocBlockData
- AllocChunkData

---

## MemoryContext

```c
typedef struct MemoryContextData
{
    NodeTag       type;         /* identifies exacts kind of context */
    MemoryContextMethods *methods;  /* virtual function table */
    MemoryContext parent;        /* NULL if no parent (toplevel context) */
    MemoryContext firstchild;    /* head of linked list of children */
    MemoryContext nextchild;     /* next child of same parent */
    char         *name;          /* context name (just for debugging) */
} MemoryContextData;

typedef struct MemoryContextData *MemoryContext;
```
MemoryContext中的methods字段是一个MemoryContextMethods类型，它是由一系列的函数指针组成的集合，其中包含了对内存上下文操作的函数。对不同的MemoryContext实现，可以设置不同的方法集合。目前MemoryContext中只有AllocSetContext一种实现，因此PostgreSQL中只有针对AllocSetContext的一种操作函数集合，由全局变量AllocSetMethods表示。

---

## MemoryContextMethods

```c
typedef struct MemoryContextMethods
{
    void       *(*alloc) (MemoryContext context, Size size);
    /* call this free_p in case someone #define's free() */
    void        (*free_p) (MemoryContext context, void *pointer);
    void       *(*realloc) (MemoryContext context, void *pointer, Size size);
    void        (*init) (MemoryContext context);
    void        (*reset) (MemoryContext context);
    void        (*delete) (MemoryContext context);
    void        (*reuse) (MemoryContext context);
    Size        (*get_chunk_space) (MemoryContext context, void *pointer);
    bool        (*is_empty) (MemoryContext context);
    void        (*stats) (MemoryContext context);
    bool        (*is_realempty)(MemoryContext context);
#ifdef MEMORY_CONTEXT_CHECKING
    void        (*check) (MemoryContext context);
#endif
} MemoryContextMethods;
```

---

## 方法集

```c
static MemoryContextMethods AllocSetMethods = {
    AllocSetAlloc,
    AllocSetFree,
    AllocSetRealloc,
    AllocSetInit,
    AllocSetReset,
    AllocSetDelete,
    AllocSetReuse,
    AllocSetGetChunkSpace,
    AllocSetIsEmpty,
    AllocSetStats,
    AllocSetIsRealEmpty
#ifdef MEMORY_CONTEXT_CHECKING
    ,AllocSetCheck
#endif
};
```

---

MemoryContext是一个抽象类，可以有多个实现，目前只有AllocSetContext一个实现。MemoryContext并不管理实际上的内存分配，仅仅用作对MemoryContext树的控制。管理一个内存上下文中的内存块时通过AllocSet结构来完成的，MemoryContext作为AllocSet的头部信息存在。

---

## AllocSet

```c
typedef struct AllocSetContext
{
    MemoryContextData header;  /* Standard memory-context fields */
    /* Info about storage allocated in this context: */
    AllocBlock  blocks;        /* head of list of blocks in this set */
    AllocChunk  freelist[ALLOCSET_NUM_FREELISTS]; /* free chunk lists */
    bool        isReset;       /* T = no space alloced since last reset */
    /* Allocation parameters for this context: */
    Size        initBlockSize; /* initial block size */
    Size        maxBlockSize;  /* maximum block size */
    Size        nextBlockSize; /* next block size to allocate */
    AllocBlock  keeper;        /* if not NULL, keep this block over resets */
} AllocSetContext;

typedef AllocSetContext *AllocSet;
```
blocks是内存块链表，freelist是内存片链表。AllocSet所管理的内存区域被分成若干个内存块（AllocBlockData结构），每个内存块又被分成多个内存片（AllocChunkData结构）。palloc申请到的内存实际上都是内存片（除了超大块）。

---

## AllocBlockData
```c
typedef struct AllocBlockData
{
    AllocSet    aset;     /* aset that owns this block */
    AllocBlock  next;     /* next block in aset's blocks list */
    char       *freeptr;  /* start of free space in this block */
    char       *endptr;   /* end of space in this block */
} AllocBlockData;
```

---

## AllocChunkData
```c
typedef struct AllocChunkData
{
    /* aset is the owning aset if allocated, or the freelist link if free */
    void       *aset;
    /* size is always the size of the usable space in the chunk */
    Size        size;
#ifdef MEMORY_CONTEXT_CHECKING
    /* when debugging memory usage, also store actual requested size */
    /* this is zero in a free chunk */
    Size        requested_size;
#endif
} AllocChunkData;
```

---

![](/img/内存上下文结构.png)

---

# 重要函数

| 函数                    | 功能            |
| --------------------- | ------------- |
| MemoryContextCreate   | 创建上下文节点       |
| AllocSetContextCreate | 创建上下文实例       |
| MemoryContextDelete   | 删除内存上下文       |
| MemoryContextReset    | 重置内存上下文       |
| MemoryContextSwitchTo | 切换当前上下文       |
| palloc                | 在当前上下文中申请内存   |
| pfree                 | 释放内存          |
| repalloc              | 在当前上下文中重新申请内存 |

---

## 总体流程

![](/img/内存上下文总体应用.png)

---

## palloc流程

![](/img/palloc.png)

---

## pfree流程

![](/img/pfree.png)

---

# 重要的内存上下文

| 内存上下文                 | 生命周期        | 描述                              |
| --------------------- | ----------- | ------------------------------- |
| TopMemoryContext      | session     | 根节点                             |
| PostmasterContext     | session     | postmaster工作上下文                 |
| CacheMemoryContext    | session     | backend的relcache、catcache等使用    |
| MessageContext        | session     | 保存从前端传来的命令以及派生的存储，比如查询计划树和查询分析树 |
| TopTransactionContext | transaction | 一般保存跨越多个子事务的状态和控制信息             |
| CurTransactionContext | transaction | 当前事务上下文                         |

---

| 内存上下文         | 生命周期    | 描述                                       |
| ------------- | ------- | ---------------------------------------- |
| PortalContext | portal  | 全局变量，指向当前portal                          |
| ErrorContext  | session | 错误处理上下文， errstart、errfinish、errmsg等在此分配内存 |

---

# 打印内存上下文树

in smmgr/aset.c, add `#include "utils/memutils.h"`
in AllocSetContextCreate function, add
```c
fprintf(stderr, "pid=%d, Create Memory Context name is %s, parent context is %s\n",
		MyProcPid, name, (parent == NULL ? "null" : parent->name));
```

in mmgr/mcxt.c, add `#include "miscadmin.h"`
in MemoryContextDelete function, add
```c
fprintf(stderr, "pid=%d, delete memory context name is %s, parent is %s\n",
		MyProcPid, context->name, (context->parent == NULL? 'null' : context->parent->name));
```

in MemoryContextReset function, add
```c
fprintf(stderr, "pid=%d, reset memory context name is %s, parent is %s\n",
		MyProcPid, context->name, (context->parent == NULL? 'null' : context->parent->name));
```

---

# 代码结构

```
src/backend/utils/mmgr/mcxt.c
src/backend/utils/mmgr/aset.c
src/include/utils/memutils.h
src/include/nodes/memnodes.h
```
