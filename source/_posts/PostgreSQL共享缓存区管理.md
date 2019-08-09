---
layout: _post
title: PostgreSQL共享缓存区管理
date: 2018-01-11 15:30:31
tags: PostgreSQL
categories: PostgreSQL
---

# 共享缓冲区
PostgreSQL中的buffer主要是用来将外存中的数据内容读入到内存中，加速运算过程中对数据的访问速度，同时将数据的修改进行缓存，在必要时再将其写出到外存，避免频繁的I/O，以提高效率。
Buffer的种类有很多如Audit buffers、Clog buffers、Data buffers和Xlog buffers，此处所介绍的buffer管理是针对Data buffers而言的。

# 数据结构
- BufferTag
- BufferDesc
- BufferStrategyControl

## BufferTag
```c
typedef struct buftag
{
    Oid dbid;            /* database identifier */
    FileBlock blockNum;  /* file and blocknumber */
} BufferTag;
```

## BufferDesc
```c
typedef struct sbufdesc
{
    BufferTag   tag;              /* ID of page contained in buffer */
    RelFileNode rnode;            /* relation this block belongs to */
    BufFlags    flags;            /* see bit definitions above */
    uint16      usage_count;      /* usage counter for clock sweep code */
    unsigned    refcount;         /* # of backends holding pins on buffer */
    int         wait_backend_pid; /* backend PID of pin-count waiter */

    slock_t     buf_hdr_lock;     /* protects the above fields */

    int         buf_id;           /* buffer's index number (from 0) */
    int         freeNext;         /* link in freelist chain */

    LWLockId    io_in_progress_lock; /* to wait for I/O to complete */
    LWLockId    content_lock;     /* to lock access to buffer contents */
} BufferDesc;
```

## 引用计数（BufferDesc.refcount）
引用计数（refcount）用于跟踪访问buffer的后台数量，防止错误的将正在被使用的Buffer淘汰。当使用Buffer时，需要将其引用计数（refcount）加1（PinBuffer）。当Buffer不再使用，需要将其引用计数（refcount）减1（UnpinBuffer）。这里需要注意，由于一个后台可以多次访问同一个Buffer，因此后台通过PrivateRefCount来记录自己的引用次数，只有当自己对一个Buffer的引用减少到0，才会真正去修改refcount。PrivateRefCount在后台PinBuffer时将其值加1，UnpinBuffer时将其值减1。

## 使用计数（BufferDesc.usage_count）
usage_count用来标记Buffer被使用的次数，usage_count值越大，说明该Buffer经常被使用，那么在未来的一段时间里被使用的可能就比较大，所以这样的Buffer不能作为被替换的对象；相反，usage_count值越小，说明经常不被使用，可以作为替换的对象。在PostgreSQL中，只有当usage_count为0时，才可能作为替换的对象。
usage_count是在一个后台不再使用该Buffer即UnpinBuffer将后台的PrivateRefCount减少为0的时候将其值加1，以表示该Buffer最近被一个后台使用了。对VACUUN操作来说，不会修改usage_count的值，且如果refcount和usage_count的值都为0，则将buffer放入到FreeList的尾部。

## BufferStrategyControl
```c
typedef struct
{
    int    nextVictimBuffer; // 指向下一Buffer
    int    firstFreeBuffer;  // 第一个空闲缓冲块id
    int    lastFreeBuffer;   // 最后一个空闲缓冲块id
} BufferStrategyControl;

/* Pointers to shared state */
static MT_LOCAL BufferStrategyControl
	*StrategyControl = NULL;
```

## Buffer Descriptors
![](/img/BufferDescriptor.png)


# 主要函数
- InitBufferPool
- BufferAlloc
- StrategyGetBuffer
- FlushBuffer
- PinBuffer
- UnpinBuffer

## InitBufferPool流程
![](/img/InitBufferPool.svg)

## BufferAlloc流程
![](/img/BufferAlloc.svg)

# 缓冲区替换策略
- FreeList
- Clock-sweep
- buffer-ring

## FreeList
当执行DROP TABLE时，可以确定该表的所有buffer都会失效，因此将此表的所有buffer都放入到Freelist的头部，这样可以在下一次分配buffer时，直接从Freelist中得到buffer，而不需要执行Clock Sweep算法。

## Clock-sweep
当Buffer的refcount计数变成0的时候，代表当前系统没有后台引用此数据块。在PostgreSQL中，为了能够减低锁的粒度、提高并发性，引用计数等于0的的Buffer并没有被放入Freelist中。在随机访问大量磁盘块、并且没有VACUUM的干扰下，Freelist几乎是空的（除了刚刚启动时）。这里的策略主要是为了避免不必要的持有操作Freelist的互斥锁。
由于大部分时候Buffer不会立即被放入到Freelist中，因此使用了一种被称为Clock Sweep的算法来分配Buffer。此算法类似教科书中时钟算法，每当需要使用Clock Sweep算法选择一个Buffer时，就从上次分配的Buffer的下一个位置开始，搜索引用计数为0（既没有被pin的Buffer）且usage_count为0的Buffer。如果该Buffer不满足上述条件，就将usage_count减1。

## Clock-sweep
![](/img/Clock-sweep.png)
> 在上图中Clock Sweep算法从4号buffer开始查找（记录在StrategyControl结构体中）可用的buffer。4号buffer因为引用计数大于0，因此不能被替换。5号buffer虽然没有人引用，但是其usage_count大于0，因此表示此buffer使用频率较高，因此将usage_count减1，并查看6号buffer。6号buffer的引用计数和usage_count都为0，因此选择将6号buffer淘汰。记录下一次搜索的位置是7号，并退出选择算法。

## buffer-ring
批量读或者vacuum等操作可能会需要占据大量的buffer，影响其他正常业务。buffer-ring机制在批量读等占用的buffer数量达到某个程度（比如总buffer的1/4）时，分配给该操作固定的buffer数量，之后只能使用为其分配的buffer，而不能替换其他buffer。
