---
title: 排序算法
date: 2017-10-22
categories: 算法
tags: 排序
---

# 冒泡排序

```c
#include <stdio.h>
#include <stdlib.h>

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

# 快速排序

```c
#include <stdio.h>
#include <stdlib.h>

static void RandInitArray(int *arr, int num);
static void PrintArray(int *arr, int num);
static void QuickSortAsc(int *arr, int left, int right);

#define ARR_SIZE 20

int main()
{
	int arr[ARR_SIZE];
	RandInitArray(arr, ARR_SIZE);
	QuickSortAsc(arr, 0, ARR_SIZE-1);
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

static void QuickSortAsc(int *arr, int left, int right)
{
	int low, high;
	int key;

	if (left < right)
	{
		low = left;
		high = right;
		key = arr[low];

		while (low < high)
		{
			while (low < high && key <= arr[high])
				high--;
			arr[low] = arr[high];

			while (low < high && key > arr[low])
				low++;
			arr[high] = arr[low];
		}
		arr[low] = key;

		QuickSortAsc(arr, left, low-1);
		QuickSortAsc(arr, low+1, right);
	}
}
```

# 选择排序

```c
#include <stdio.h>
#include <stdlib.h>

static void RandInitArray(int *arr, int num);
static void PrintArray(int *arr, int num);
static void SelectSortAsc(int *arr, int num);

#define ARR_SIZE 20

int main()
{
	int arr[ARR_SIZE];
	RandInitArray(arr, ARR_SIZE);
	SelectSortAsc(arr, ARR_SIZE);
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

static void SelectSortAsc(int *arr, int num)
{
	int i, j;
	int min, tmp;

	for (i=0; i<num-1; i++)
	{
		min = i;

		for (j=i+1; j<num; j++)
		{
			if (arr[min] > arr[j])
				min = j;
		}

		if (min != i)
		{
			tmp = arr[min];
			arr[min] = arr[i];
			arr[i] = tmp;
		}
	}
}
```

