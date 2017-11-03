---
title: 排序算法
date: 2017-10-22
categories: 算法
tags: 排序
---

# 冒泡排序

```c
#include <stdio.h>

static void RandInitArray(int *arr, int num);
static void PrintArray(int *arr, int num);
static void BubbleSortAsc(int *arr, int num);

#define ARR_SIZE 20

int main()
{
	int arr[ARR_SIZE];

	RandInitArray(arr, ARR_SIZE);

	BubbleSortAsc(arr, ARR_SIZE);

	PrintArray(arr, ARR_SIZE);
}

static void RandInitArray(int *arr, int num)
{
	int i;

	for (i=0; i<num; i++)
		arr[i] = random()%100;
}

static void PrintArray(int *arr, int num)
{
	int i;

	for (i=0; i<num; i++)
		printf("%d ", arr[i]);
	printf("\n");
}

static void BubbleSortAsc(int *arr, int num)
{
	int i, j;
	int temp;

	for (i=0; i<num-1; i++)
	{
		for (j=0; j<num-1-i; j++)
		{
			if (arr[j] > arr[j+1])
			{
				temp = arr[j];
				arr[j] = arr[j+1];
				arr[j+1] = temp;
			}
		}
	}
}
```

