---
layout: _post
title: 常用的c语言函数
date: 2018-12-06 14:45:14
categories: 编程
tags:
---

# 日志相关

```c
// 把标准错误和标准输出重定位到文件
bool setLogFile(const char *logFile)
{
    if ((Logfilefd = open(Logfile, O_WRONLY | O_CREAT | O_APPEND, 0644)) == -1) 
    {   
        fprintf(stderr, "Open logfile %s failed.\n", Logfile);
        return false;
    }   

    close(1);
    close(2);
    dup2(Logfilefd, 1); 
    dup2(Logfilefd, 2); 
    close(Logfilefd);

    return true;
}

#define LOG(fmt, ...) \
    do { \
        fprintf(stdout, "%s [LOG]:--"fmt"--%s:%d\n", \
                GetCurrentTime(), ##__VA_ARGS__, __FILE__, __LINE__); \
    } while (0)

#define ELOG(fmt, ...) \
    do { \
        fprintf(stderr, "%s [ERROR]:--"fmt"--%s:%d\n", \
                GetCurrentTime(), ##__VA_ARGS__, __FILE__, __LINE__); \
    } while (0)

#define DLOG(fmt, ...) \
    do { \
        if (EnableDebug) \
            fprintf(stdout, "%s [DEBUG]:--"fmt"--%s:%d\n", \
                    GetCurrentTime(), ##__VA_ARGS__, __FILE__, __LINE__); \
    } while (0)

# 二进制转十六机制

```c
// 把二进制转换成十六进制并以字符串形式写到文件
#define Bin2HexFp(fp,src,n) \
    do { \
        int _bi; \
        for (_bi=0; _bi<n; _bi++) fprintf(fp, "%02X", (src)[_bi]); \
        fprintf(fp, "\n"); \
    } while (0)
```

# 阻塞

```c
bool SetNonblock(int socket)
{
    int flag = 0;
    if ((flag = fcntl(socket, F_GETFL, 0)) < 0)
        return false;
    if (fcntl(socket, F_SETFL, flag | O_NONBLOCK) < 0)
        return false;
    return true;
}

ssize_t BlockRead(int fd, void *buf, size_t n)
{
    size_t nleft;
    ssize_t nread;
    unsigned char *pb;

    pb = buf;
    nleft = n;

    while (nleft > 0)
    {
        if ((nread = read(fd, pb, nleft)) < 0)
        {
            if (errno == EINTR)
                continue;
            return -1;
        }
        else if (nread == 0) /* Peer close the connection */
            return 0;

        nleft -= nread;
        pb += nread;
    }
    return n - nleft;
}

ssize_t BlockWrite(int fd, void *buf, size_t n)
{
    size_t nleft;
    ssize_t nwritten;
    unsigned char *pb;

    pb = buf;
    nleft = n;

    while (nleft > 0)
    {
        if ((nwritten = write(fd, pb, nleft)) < 0)
        {
            if (errno == EINTR)
                nwritten = 0;
            else
                return -1;
        }
        else if (nwritten == 0)
            return 0;

        nleft -= nwritten;
        pb += nwritten;
    }
    return n - nleft;
}
```

# 程序运行

```shell
const char *GetProgname(const char *argv0)
{
    char *p;

    p = strrchr(argv0, '/');
    if (p == NULL)
        return argv0;
    else
        return p+1;
}

char *MakeAbsolutePath(const char *path)
{
    char *new;

    if (path == NULL)
        return NULL;

    if (path[0] == '/')
    {
        new = strdup(path);
        if (new == NULL)
            return NULL;
    }
    else
    {
        char *buf;
        size_t bufLen;

        bufLen = 1024;
        for (;;)
        {
            buf = malloc(bufLen);
            if (buf == NULL)
                return NULL;

            if (getcwd(buf, bufLen))
                break;
            else if (errno == ERANGE)
            {
                free(buf);
                bufLen *= 2;
                continue;
            }
            else
          	{
                free(buf);
                return NULL;
            }   
        }   
        
        new = malloc(strlen(buf) + strlen(path) + 2);
        if (new == NULL)
        {
            free(buf);
            return NULL;
        }   
        sprintf(new, "%s/%s", buf, path);
        free(buf);
    }   
    
    return new;
}

bool IsAlreadyRunning(const char *path)
{
    int          fd;
    char         buf[16];
    struct flock fl;

    if ((fd = open(path, O_RDWR | O_CREAT, 0644)) == -1)
        return true;

    fl.l_type = F_WRLCK;
    fl.l_whence = SEEK_SET;
    fl.l_start = 0;
    fl.l_len = 0;
    fl.l_pid = getpid();
    if (fcntl(fd, F_SETLK, &fl) == -1)
    {
        close(fd);
        return true;
    }

    ftruncate(fd, 0);
    snprintf(buf, 16, "%ld", (long)getpid());
    write(fd, buf, strlen(buf)+1);

    return false;
}
```

# 随机数

```c
void GenerateString(unsigned char *dest, int len)
{
    int i;
    char allChar[] = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    int cLen = strlen(allChar);

    srand(time(NULL));

    for (i=0; i<len-1; i++)
    {
        *dest = allChar[rand() % cLen];
        dest++;
    }
    *dest = '\0';
}
```

# 时间相关

```c
char *GetCurrentTime(void)
{
    static char _CurrentTime[27];
    struct timeval tv;
    struct tm *tp;

    snprintf(_CurrentTime, 27, "unknown time");

    if (gettimeofday(&tv, NULL) == -1)
        return _CurrentTime;

    if ((tp = localtime(&tv.tv_sec)) == NULL)
        return _CurrentTime;

    snprintf(_CurrentTime, 27, "%04d-%02d-%02d %02d:%02d:%02d.%06ld",
            tp->tm_year+1900, tp->tm_mon+1, tp->tm_mday,
            tp->tm_hour, tp->tm_min, tp->tm_sec, tv.tv_usec);

    return _CurrentTime;
}
```

# 数字判断

```c
bool IsDigitals(const char *s)
{
    const char *p = s;

    if (s == NULL || *s == '\0')
        return false;

    if (*p == '-')
        p++;

    for (; *p!='\0'; p++)
    {
        if (*p < '0' || *p > '9')
            return false;
    }

    return true;
}

bool IsNonnegativeInteger(char *data)
{
    char *p;

    if (data == NULL || data[0] == '\0')
        return false;

    p = data;
    for (p=data; *p!='\0'; p++)
    {
        if (*p<'0' || *p>'9')
            return false;
    }

    return true;
}
```

# mac地址

```c
// 根据socket获取mac地址
bool GetLocalMac(int fd, char delimiter, char *mac, size_t macLen)
{
    struct ifaddrs *ifaddr = NULL;
    struct ifaddrs *ifp = NULL;
    struct ifreq    ifr;
    struct sockaddr_in *inp;
    char *ifname;
    struct sockaddr_in in;
    socklen_t inLen;

    inLen = sizeof(in);
    memset(&in, 0, inLen);
    if (getsockname(fd, (struct sockaddr*)&in, &inLen) != 0)
        return false;

    if (getifaddrs(&ifaddr) != 0)
        return false;

    for (ifp=ifaddr; ifp!=NULL; ifp=ifp->ifa_next)
    {   
        inp = (struct sockaddr_in*)ifp->ifa_addr;
        if (inp != NULL &&
                inp->sin_family == in.sin_family &&
                inp->sin_addr.s_addr == in.sin_addr.s_addr)
            break;
    }
    if (ifp == NULL)
    {   
        freeifaddrs(ifaddr);
        return false;
    }
    ifname = ifp->ifa_name;
  	strncpy(ifr.ifr_name, ifname, IFNAMSIZ);
    if (ioctl(fd, SIOCGIFHWADDR, &ifr) == -1)
    {
        freeifaddrs(ifaddr);
        return false;
    }

    freeifaddrs(ifaddr);

    snprintf(mac, macLen, "%02X%c%02X%c%02X%c%02X%c%02X%c%02X",
            (unsigned char)ifr.ifr_hwaddr.sa_data[0], delimiter,
            (unsigned char)ifr.ifr_hwaddr.sa_data[1], delimiter,
            (unsigned char)ifr.ifr_hwaddr.sa_data[2], delimiter,
            (unsigned char)ifr.ifr_hwaddr.sa_data[3], delimiter,
            (unsigned char)ifr.ifr_hwaddr.sa_data[4], delimiter,
            (unsigned char)ifr.ifr_hwaddr.sa_data[5]);

    return true;
}

// 根据socket获取对端mac地址
bool GetPeerMac(int fd, struct sockaddr *from,
        socklen_t fromLen, char delimiter, char *mac, size_t macLen)
{
    struct ifaddrs *ifaddr = NULL;
    struct ifaddrs *ifp = NULL;
    struct sockaddr_in *inp;
    char *ifname;
    struct sockaddr_in in;
    socklen_t inLen;
    struct arpreq arp;

    inLen = sizeof(in);
    memset(&in, 0, inLen);
    if (getsockname(fd, (struct sockaddr*)&in, &inLen) != 0)
        return false;

    if (getifaddrs(&ifaddr) != 0)
        return false;

    for (ifp=ifaddr; ifp!=NULL; ifp=ifp->ifa_next)
    {
        inp = (struct sockaddr_in*)ifp->ifa_addr;
        if (inp != NULL &&
                inp->sin_family == in.sin_family &&
                inp->sin_addr.s_addr == in.sin_addr.s_addr)
            break;
    }
    if (ifp == NULL)
    {
        freeifaddrs(ifaddr);
        return false;
    }
    ifname = ifp->ifa_name;

    memset(&arp, 0, sizeof(arp));
    memcpy(&arp.arp_pa, from, fromLen);
  	strncpy(arp.arp_dev, ifname, 16);
    if (ioctl(fd, SIOCGARP, &arp) == -1)
    {
        freeifaddrs(ifaddr);
        return false;
    }

    freeifaddrs(ifaddr);

    snprintf(mac, macLen, "%02X%c%02X%c%02X%c%02X%c%02X%c%02X",
            arp.arp_ha.sa_data[0], delimiter,
            arp.arp_ha.sa_data[1], delimiter,
            arp.arp_ha.sa_data[2], delimiter,
            arp.arp_ha.sa_data[3], delimiter,
            arp.arp_ha.sa_data[4], delimiter,
            arp.arp_ha.sa_data[5]);

    return true;
}
```
# 参数处理

```shell
#include <fcntl.h>
#include <getopt.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>

#ifndef bool
typedef unsigned char bool;
#define true 1
#define false 0
#endif

#define _(x) (x)

#define ELOG(fmt, args...) \
    do { \
        fprintf(stderr, "[ERROR]:--"fmt"--%s:%d\n", \
                ##args, __FILE__, __LINE__); \
    } while (0)

static const char *Progname;
static const char *SubProgram = NULL;
static char       *Opts;
static void       (*Func)(void);

static int    ProductionLimit = -1;
static int    ConnectionLimit = -1;
static time_t Deadline = 0xFFFFFFFF;
static char  *UpdateFile = "./update.bin";
static char  *Hid = NULL;
static char  *Logo = "";
static char  *Protocol = "CCID";
static bool   SetNetwork = false;
static bool   SetLogo = false;
static bool   SetDeadline = false;
static bool   SetUnlock = false;
static bool   SetMotherMode = false;
static bool   IsEmpty = false;
static bool   EnableVerbose = false;
static bool   EnableDebug = false;

static void Usage(void);
static void FormLogo(char *logo);
static bool StrToTime(const char *str, time_t *t);
static bool IsDigitals(const char *str);
const char *GetProgname(const char *argv0);

static void MCInit(void);
static void Init(void);
static void MakeUpdate(void);
static void Update(void);
static void Reset(void);
static void List(void);
static void SwitchProtocol(void);

static struct ExecStringOpts
{
    char    *string;
    char    *opts;
    void    (*func)(void);
} ExecStringOpts[] =
{
    {"mcinit", "H:F:P:", MCInit},
    {"init", "D:H:L:M:N:P:", Init},
    {"makeupdate", "D:F:H:L:N:U1", MakeUpdate},
    {"update", "H:F:", Update},
    {"reset", "H:", Reset},
    {"list", "H:v", List},
    {"switch", "H:P:", SwitchProtocol},
    {NULL, NULL, NULL}
};

int main(int argc, char **argv)
{
    static struct option long_options[] = {
        {"debug", no_argument, NULL, 'd'},    /* enable debug */
        {"empty", no_argument, NULL, '1'},    /* is empty dongle */
        {"local", no_argument, NULL, '2'},    /* is empty dongle */
        {NULL, required_argument, NULL, 'D'}, /* deadline */
        {NULL, required_argument, NULL, 'F'}, /* update file path */
        {NULL, required_argument, NULL, 'H'}, /* hid */
        {NULL, required_argument, NULL, 'L'}, /* logo */
        {NULL, required_argument, NULL, 'M'}, /* init a mother dongle? default child dongle */
        {NULL, required_argument, NULL, 'N'}, /* network client number */
        {NULL, required_argument, NULL, 'P'}, /* admin pin */
        {NULL , no_argument, NULL, 'U'},      /* unlock user pin */
        {NULL , no_argument, NULL, 'v'},      /* list dongle verbose information */
        {NULL, 0, NULL, 0}
    };
    int c, option_index;
    int i;

    Progname = GetProgname(argv[0]);

    Opts = ExecStringOpts[i].opts;
    Func = MCInit;
    
    if (argc > 1)
    {
        for (i=0; ExecStringOpts[i].string!=NULL; i++)
        {
            if (strcasecmp(argv[1], ExecStringOpts[i].string) == 0)
            {
                SubProgram = ExecStringOpts[i].string;
                Opts = ExecStringOpts[i].opts;
                Func = ExecStringOpts[i].func;
                argc--;
                argv++;
                break;
            }
        }
    }

    if (argc > 1)
    {
        if (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-?") == 0)
        {
            Usage();
            exit(0);
        }
        if (strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-V") == 0)
        {
            exit(0);
        }
    }
    
    while ((c = getopt_long(argc, argv, Opts, long_options, &option_index)) != -1)
    {
        switch (c)
        {
            case 'D':
                SetDeadline = true;
                if (!StrToTime(optarg, &Deadline))
                {
                    ELOG("Time format error");
                    return 1;
                }
                break;
            case 'd':
                EnableDebug = true;
                break;
            case 'F':
                UpdateFile = optarg;
                break;
            case 'H':
                Hid = optarg;
                break;
            case 'L':
                SetLogo = true;
                Logo = optarg;
                FormLogo(Logo);
                break;
            case 'M':
                SetMotherMode = true;
                if (!IsDigitals(optarg))
                {
                    ELOG("Option format error");
                    return 1;
                }
                ProductionLimit = atoi(optarg);
                break;
            case 'N':
            	SetNetwork = true;
                if (!IsDigitals(optarg))
                {
                    ELOG("Option format error");
                    return 1;
                }
                ConnectionLimit = atoi(optarg);
                break;
            case 'P':
                Protocol = optarg;
                break;
            case 'U':
                SetUnlock = true;
                break;
            case 'v':
                EnableVerbose = true;
                break;
            case '1':
                IsEmpty = true;
                break;
            default:
                if (SubProgram != NULL)
                    fprintf(stderr, "Try \"%s %s --help\" for more information.\n",
                            Progname, SubProgram);
                else
                    fprintf(stderr, "Try \"%s --help\" for more information.\n",
                            Progname);
                return 1;
        }
    }
    
    if (optind < argc)
    {
        fprintf(stderr, "Invalid argument: \"%s\".\n", argv[optind]);
        return 1;
    }

    Func();
    
    return 0;
}

static void Usage(void)
{
    printf(_("%s is a super dongle tool.\n\n"), Progname);
    printf(_("Usage:\n"));
    if (SubProgram == NULL || *SubProgram == '\0')
    {
        printf(_("  %s [mcinit] [OPTION]\n"), Progname);
        printf(_("  %s init [OPTION]\n"), Progname);
        printf(_("  %s mamkeupdate [OPTION]\n"), Progname);
        printf(_("  %s update [OPTION]\n"), Progname);
        printf(_("  %s reset [OPTION]\n"), Progname);
        printf(_("  %s list [OPTION]\n"), Progname);
        printf(_("  %s switch [OPTION]\n"), Progname);
    }
    else
        printf(_("  %s %s [OPTION]\n"), Progname, SubProgram);
    printf(_("\nOptions:\n"));
    if (strchr(Opts, 'D') != NULL)
    {
        printf(_("  -D DEADLINE          set expiration time\n"));
        printf(_("                       \"unlimited\"\n"));
        printf(_("                       \"yyyy-mm-dd hh:mm:ss\" (1977-06-23 23:00:00 ~ 2038-01-19 11:14:07)\n"));
        printf(_("                       \"hours\" (1 ~ 65535)\n"));
    }
    if (strchr(Opts, 'F') != NULL)
        printf(_("  -F FILE              update file path (default %s)\n"), UpdateFile);
    if (strchr(Opts, 'H') != NULL)
        printf(_("  -H HID               dongle hid\n"));
    if (strchr(Opts, 'L') != NULL)
    {
        printf(_("  -L LOGO              logo separated by \";\"\n"));
        printf(_("                       \"CustomerName: xxx;ProjectCode: 0x123;ProjectName: yyy\"\n"));
    }
    if (strchr(Opts, 'M') != NULL)
        printf(_("  -M NUM               initialize a mother dongle\n"));
    if (strchr(Opts, 'N') != NULL)
    	printf(_("  -N NUM               set to network mode, and set connection limit"
                    "(default local mode)\n"));
    if (strchr(Opts, 'P') != NULL)
        printf(_("  -P PROTOCOL          communication protocol, default CCID\n"));
    if (strchr(Opts, 'U') != NULL)
        printf(_("  -U                   unlock user pin\n"));
    if (strchr(Opts, 'v') != NULL)
        printf(_("  -v                   view details\n"));
    if (strchr(Opts, '1') != NULL)
        printf(_("  --empty              empty dongle\n"), UpdateFile);
    printf(_("  -?,--help            show help\n"));
}
static void FormLogo(char *logo)
{}
static bool StrToTime(const char *str, time_t *t)
{
    struct tm tm; 

    if (strcasecmp(str, "unlimited") == 0) /* unlimited */
    {   
        *t = 0xFFFFFFFF;
        return true;
    }   

    if (sscanf(str, "%d-%d-%d %d:%d:%d",
                &tm.tm_year, &tm.tm_mon, &tm.tm_mday,
                &tm.tm_hour, &tm.tm_min, &tm.tm_sec) == 6) /* xxxx-xx-xx xx:xx:xx */
    {   
        if (tm.tm_year < 1977 || tm.tm_year > 2038 ||
                tm.tm_mon < 1 || tm.tm_mon > 12 ||
                tm.tm_mday < 1 || tm.tm_mday > 31 ||
                tm.tm_hour > 24 || tm.tm_min > 60 || tm.tm_sec > 60) 
            return false;

        if (tm.tm_year == 1977 &&
                (tm.tm_mon < 6 ||
                 (tm.tm_mon == 6 &&
                  (tm.tm_mday < 23 ||
                   (tm.tm_mday == 23 &&
                    (tm.tm_hour < 23))))))
                return false;

        if (tm.tm_year == 2038 &&
                (tm.tm_mon > 1 ||
                 (tm.tm_mon == 1 &&
                  (tm.tm_mday > 19 ||
                   (tm.tm_mday == 19 &&
                    (tm.tm_hour > 11 ||
                     (tm.tm_hour == 11 &&
                      (tm.tm_min > 14 ||
                       (tm.tm_min == 14 &&
                        (tm.tm_sec > 7))))))))))
                return false;

        tm.tm_year -= 1900;
        tm.tm_mon--;
        tm.tm_isdst = -1;
        if ((*t = mktime(&tm)) == -1)
            return false;
        return true;
    }

    /* xxx hours */
    if (!IsDigitals(str))
        return false;

    *t = atoi(str);
    if (*t < 1 || *t > 0xFFFF)
        return false;

    return true;
}
static bool IsDigitals(const char *str)
{
  	return true;
}
const char *GetProgname(const char *argv0)
{
    char *p;

    p = strrchr(argv0, '/');
    if (p == NULL)
        return argv0;
    else
        return p+1;
}
static void MCInit(void)
{}
static void Init(void)
{}
static void MakeUpdate(void)
{}
static void Update(void)
{}
static void Reset(void)
{}
static void List(void)
{}
static void SwitchProtocol(void)
{}
```

