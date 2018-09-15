---
layout: _post
title: 查看linux信息
date: 2018-09-15 11:42:13
categories: 操作系统
tags:
- cpuinfo
- fdisk
- linux
---

# 系统信息

## 内核和架构

```shell
$ # uname --help
  -a, --all                print all information, in the following order,
                             except omit -p and -i if unknown:
  -s, --kernel-name        print the kernel name
  -n, --nodename           print the network node hostname
  -r, --kernel-release     print the kernel release
  -v, --kernel-version     print the kernel version
  -m, --machine            print the machine hardware name
  -p, --processor          print the processor type or "unknown"
  -i, --hardware-platform  print the hardware platform or "unknown"
  -o, --operating-system   print the operating system
      --help     display this help and exit
      --version  output version information and exit

# 所有信息
$ uname -a
Linux h113 2.6.32-696.10.1.el6.x86_64 #1 SMP Tue Aug 22 18:51:35 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux

# 以“|”分割的所有信息
$ echo "`uname -s` | `uname -n` | `uname -r` | `uname -v` | `uname -m` | `uname -p` | `uname -i` | `uname -o`"
Linux | h113 | 2.6.32-696.10.1.el6.x86_64 | #1 SMP Tue Aug 22 18:51:35 UTC 2017 | x86_64 | x86_64 | x86_64 | GNU/Linux
```

## 操作系统

```shell
$ cat /etc/issue
CentOS release 6.4 (Final)
Kernel \r on an \m
```

## 语言和字符集

```shell
$ echo $LANG 
en_US.UTF-8

$ locale
LANG=en_US.UTF-8
LC_CTYPE="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
LC_ALL=
```

## 进程

```shell
# 显示系统所有进程
$ ps -ef

# 以树形显示所有进程
$ ps -ef f
```

## 其他

```shell
$ uptime          #查看服务器开机时长，用户数，平均负载
$ lsmod           #查看所有加载的模块
$ env             #查系统环境变量
$ crontab -l      #查看计划任务
$ top             #查看系统任务
$ iostat          #查看系统io
$ vmstate
$ netstat         #查看网络、路由、端口占用等
```

# 硬件信息

## cpu

```shell
$ cat /proc/cpu
processor	: 0
vendor_id	: GenuineIntel
cpu family	: 6
model		: 85
model name	: Intel(R) Xeon(R) Gold 6140 CPU @ 2.30GHz
stepping	: 4
microcode	: 0x2000026
cpu MHz		: 999.960
cache size	: 25344 KB
physical id	: 0
siblings	: 36
core id		: 0
cpu cores	: 18
apicid		: 0
initial apicid	: 0
fpu		: yes
fpu_exception	: yes
cpuid level	: 22
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb 
rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 
ssse3 fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch epb cat_l3 cdp_l3 
intel_pt tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm cqm mpx rdt_a avx512f avx512dq rdseed adx smap cl
flushopt clwb avx512cd avx512bw avx512vl xsaveopt xsavec xgetbv1 cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local dtherm ida arat pln pts hwp hwp_act_window
 hwp_epp hwp_pkg_req
bogomips	: 4600.00
clflush size	: 64
cache_alignment	: 64
address sizes	: 46 bits physical, 48 bits virtual
power management:

...
省略
...

processor	: 71             # 逻辑核编号：共72个逻辑cpu
vendor_id	: GenuineIntel   # 制造商
cpu family	: 6              # 产品系列
model		: 85             # 属于其系列的哪一代
model name	: Intel(R) Xeon(R) Gold 6140 CPU @ 2.30GHz
stepping	: 4
microcode	: 0x2000026
cpu MHz		: 1131.222       # 主频
cache size	: 25344 KB       # 二级缓存大小
physical id	: 1              # 单个cpu标号：共2个cpu
siblings	: 36             # 当前cpu的逻辑核数
core id		: 27             # 当前物理核在其所处cpu中的唯一编号，不一定连续
cpu cores	: 18             # 当前cpu的物理核数，siblings/cpu cores就是超线程数
apicid		: 119
initial apicid	: 119
fpu		: yes
fpu_exception	: yes
cpuid level	: 22
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 fma cx16 xtpr pdcm pcid dca sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch epb cat_l3 cdp_l3 intel_pt tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 hle avx2 smep bmi2 erms invpcid rtm cqm mpx rdt_a avx512f avx512dq rdseed adx smap clflushopt clwb avx512cd avx512bw avx512vl xsaveopt xsavec xgetbv1 cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local dtherm ida arat pln pts hwp hwp_act_window hwp_epp hwp_pkg_req
bogomips	: 4605.53
clflush size	: 64
cache_alignment	: 64
address sizes	: 46 bits physical, 48 bits virtual
power management:
```

## 内存

```shell
$ cat /proc/meminfo 
MemTotal:       196521604 kB   # 总内存
MemFree:          644068 kB    # 空闲内存
MemAvailable:   192606708 kB   # 可用内存
Buffers:             152 kB
Cached:         186042324 kB
SwapCached:            0 kB
Active:           643680 kB
Inactive:       185668932 kB
Active(anon):     203332 kB
Inactive(anon):   329264 kB
Active(file):     440348 kB
Inactive(file): 185339668 kB
Unevictable:           0 kB
Mlocked:               0 kB
SwapTotal:       4194300 kB    # 交换空间大小
SwapFree:        4194300 kB    # 空闲交换空间
Dirty:                40 kB
Writeback:             0 kB
AnonPages:        270064 kB
Mapped:           330936 kB
Shmem:            262460 kB
Slab:            7182928 kB
SReclaimable:    6933600 kB
SUnreclaim:       249328 kB
KernelStack:       20704 kB
PageTables:        17124 kB
NFS_Unstable:          0 kB
Bounce:                0 kB
WritebackTmp:          0 kB
CommitLimit:    190889820 kB
Committed_AS:    1997032 kB
VmallocTotal:   34359738367 kB
VmallocUsed:      833948 kB
VmallocChunk:   34258257916 kB
HardwareCorrupted:     0 kB
AnonHugePages:     69632 kB
HugePages_Total:       0
HugePages_Free:        0
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
DirectMap4k:      374132 kB
DirectMap2M:     8749056 kB
DirectMap1G:    192937984 kB

# 查看所有交换空间
$ swapon -s
Filename				Type		Size	Used	Priority
/dev/dm-1                               partition	16506876	240	-1
```

## 磁盘

```shell
# 树状显示所有块设备，比较直观
$ lsblk 
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda                         8:0    0   512G  0 disk 
├─sda1                      8:1    0   500M  0 part /boot
└─sda2                      8:2    0 511.5G  0 part 
  ├─vg_h95-lv_root (dm-0) 253:0    0    50G  0 lvm  /
  ├─vg_h95-lv_swap (dm-1) 253:1    0  15.8G  0 lvm  [SWAP]
  └─vg_h95-lv_home (dm-2) 253:2    0   2.1T  0 lvm  /home
sdb                         8:16   0   1.7T  0 disk 
└─sdb1                      8:17   0   1.7T  0 part 
  └─vg_h95-lv_home (dm-2) 253:2    0   2.1T  0 lvm  /home
sr0                        11:0    1  1024M  0 rom

# fdisk是分区工具，可显示磁盘详细信息，不直观
$ fdisk -l

Disk /dev/sda: 549.8 GB, 549755813888 bytes
255 heads, 63 sectors/track, 66837 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x000cde3e

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *           1          64      512000   83  Linux
Partition 1 does not end on cylinder boundary.
/dev/sda2              64       66838   536357888   8e  Linux LVM

WARNING: GPT (GUID Partition Table) detected on '/dev/sdb'! The util fdisk doesn't support GPT. Use GNU Parted.


Disk /dev/sdb: 1842.2 GB, 1842238980096 bytes
255 heads, 63 sectors/track, 223972 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x00000000

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1               1      223973  1799061503+  ee  GPT

Disk /dev/mapper/vg_h95-lv_root: 53.7 GB, 53687091200 bytes
255 heads, 63 sectors/track, 6527 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x00000000


Disk /dev/mapper/vg_h95-lv_swap: 16.9 GB, 16903045120 bytes
255 heads, 63 sectors/track, 2055 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x00000000


Disk /dev/mapper/vg_h95-lv_home: 2320.9 GB, 2320871981056 bytes
255 heads, 63 sectors/track, 282163 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x00000000
```