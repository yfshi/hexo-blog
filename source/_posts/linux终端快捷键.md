---
layout: _post
title: linux终端快捷键
date: 2018-12-27 17:28:48
categories: Shell
tags:
---

> linux中的许多操作在终端（Terminal）中十分的快捷。



* 光标操作

| 快捷键               | 功能          |
| ----------------- | ----------- |
| Ctrl+A(ahead)     | 移动到行首       |
| Ctrl+E(end)       | 移动到行尾       |
| Ctrl+Left         | 移动到上一个单词的词首 |
| Ctrl+Right        | 移动到下一个单词的词尾 |
| Ctrl+F(forwards)  | 向后移动一个字符    |
| Ctrl+B(backwards) | 向前移动一个字符    |
| Esc+F             | 移动到当前单词的词尾  |
| Esc+B             | 移动到当前单词的词首  |

* 文本处理操作

| 快捷键    | 功能                    |
| ------ | --------------------- |
| Ctrl+U | 剪切光标到行首的内容            |
| Ctrl+K | 剪切光标到行尾的内容            |
| Ctrl+W | 剪切光标到词首的内容            |
| Alt+D  | 剪切光标到词尾的内容            |
| Ctrl+H | 删除光标前的字符，相当于Backspace |
| Ctrl+D | 删除光标后的字符，相当于Delete    |
| Ctrl+Y | 粘贴删除或剪切的字符            |
| Ctrl+7 | 恢复刚才的内容               |

* 历史命令操作

| 快捷键              | 功能              |
| ---------------- | --------------- |
| Ctrl+P(previous) | 显示上一条命令         |
| Ctrl+N(next)     | 显示下一条命令         |
| !Num             | 执行命令历史表的第Num条命令 |
| !!               | 执行上一条命令         |
| !$               | 上一条命令的最后一个参数    |
| Ctrl+R(retrive)  | 向上搜索历史命令        |

* 窗口操作

| 快捷键            | 功能   |
| -------------- | ---- |
| Shift+Ctrl+N   | 新建窗口 |
| Shift+Ctrl+Q   | 关闭终端 |
| F11            | 全屏   |
| Ctrl+Plus      | 放大   |
| Ctrl+Minus     | 缩小   |
| Ctrl+0         | 原始大小 |
| Shirt+Up       | 向上滚屏 |
| Shift+Down     | 向下滚屏 |
| Shift+PageUp   | 向上翻页 |
| Shift+PageDown | 向下翻页 |

* 任务处理操作

| 快捷键    | 功能           |
| ------ | ------------ |
| Ctrl+C | 删除整行/终止      |
| Ctrl+L | 刷新屏幕         |
| Ctrl+S | 挂起当前shell    |
| Ctrl+Q | 重新启用挂起的shell |

* 标签页处理操作

| 快捷键                 | 功能             |
| ------------------- | -------------- |
| Shift+Ctrl+T        | 新建标签页          |
| Shift+Ctrl+W        | 关闭标签页          |
| Ctrl+PageUp         | 前一标签页          |
| Ctrl+PageDown       | 后一标签页          |
| Shift+Ctrl+PageUp   | 标签页左移          |
| Shift+Ctrl+PageDown | 标签页右移          |
| Alt+1,2,3...        | 切换到标签页1,2,3... |

* 其他操作