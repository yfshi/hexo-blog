---
title: 其他算法
date: 2017-10-24
categories: 算法
tags: 阶乘
---

# 大数阶乘

对于比较小的数n，可以通过递归或循环将计算结果保存为整形。但是如果n很大的时候，比如1000，那么n!肯定超出整形数据所能表示的范围。因此必须采用其他方法解决。一般是采用数组模拟。实现代码如下：

```clike
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define STORE_STEP_SIZE 100

static int s_store_size = 0;

#define EXTENT_STORE(s) { \
	s_store_size += STORE_STEP_SIZE; \
	s = realloc(s, sizeof(int) * s_store_size); \
}

#define DESTROY_STORE(s) { free(s); }

/*
 * digit:
 * 9x + x/10 <= INT_MAX
 * x = 10INT_MAX/91
 */
static void fact(int digit)
{
	int i, j;
	int temp;
	int cvalue;
	int size;
	int *store;

	if (digit < 1 || digit >= 10*((int)pow(2,31)/91))
	{
		printf("digit(%d) is too smaller or too big\n", digit);
		return;
	}

	/* 1! */
	if (digit == 1)
	{
		printf("1\n");
		return;
	}

	EXTENT_STORE(store);
	if (store == NULL)
	{
		printf("faile...\n");
		DESTROY_STORE(store);
		return;
	}

	store[0] = 1;
	size = 1;

	for (i=2; i<=digit; i++)
	{
		for (cvalue=0, j=1; j<=size; j++)
		{
			temp = store[j-1] * i + cvalue;
			store[j-1] = temp % 10;
			cvalue = temp / 10;
		}
		while (cvalue > 0)
		{
			if (size >= s_store_size)
			{
				EXTENT_STORE(store);
				if (store == NULL)
				{
					printf("fail...\n");
					DESTROY_STORE(store);
					return;
				}
			}
			store[++size - 1] = cvalue % 10;
			cvalue /= 10;
		}
	}

	for (i=size-1; i>=0; i--)
		printf("%d", store[i]);
	printf("\n");
	
	/* store's size and current size */
	//printf("s_store_size=%d, size=%d\n", s_store_size, size);

	DESTROY_STORE(store);
}

int main(int argc, char **argv)
{
	if (argc < 2)
	{
		printf("Usage: %s <digit>\n", argv[0]);
		return -1;
	}

	fact(atoi(argv[1]));

	return 0;
}
```
