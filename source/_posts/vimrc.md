---
title: vimrc
date: 2017-11-03 16:24:25
tags:
---

/etc/vimrc     System wide Vim initializations.
~/.vimrc       Your personal Vim initializations.

```shell
let mapleader=","
set nocompatible
set number
set incsearch

" 状态栏
set statusline=%F%m%r%h%w%=\ [ft=%Y]\ %{\"[fenc=\".(&fenc==\"\"?&enc:&fenc).((exists(\"+bomb\")\ &&\ &bomb)?\"+\":\"\").\"]\"}\ [ff=%{&ff}]\ [asc=%03.3b]\ [hex=%02.2B]\ [pos=%04l,%04v][%p%%]\ [len=%L]
set laststatus=2

" 自动缩进，编码
set autoindent
set cindent
set tabstop=4 shiftwidth=4 noexpandtab
set encoding=utf-8 fileencodings=ucs-bom,utf-8,cp936

"标签页
map <leader>n :tabnew <cr>
map <leader><tab> :tabnext <cr>
map <leader>1 1gt
map <leader>2 2gt
map <leader>3 3gt
map <leader>4 4gt
map <leader>5 5gt
map <leader>6 6gt
map <leader>7 7gt
map <leader>8 8gt
map <leader>9 9gt

" 鼠标
"if has('mouse')
"	set mouse=a
"endif
```
