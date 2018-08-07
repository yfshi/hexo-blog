# hexo-blog

* 安装git

* 安装nodejs
```shell
$ wget -qO- https://raw.github.com/creationix/nvm/master/install.sh | sh
$ nvm install stable
```
或者可以下载[安装程序](https://nodejs.org/en/)来安装。

* 安装hexo
```shell
$ npm install -g hexo-cli
$ npm install -g hexo-server
```

* 下载代码
```shell
$ git clone git@github.com:yfshi/hexo-blog.git
```

* 安装package
```shell
$ cd hexo-blog
$ npm install
```
npm install默认会安装package.json中dependencies和devDependencies里的所有模块.

* 启动本地server
```shell
$ hexo server
```

* 访问
浏览器访问：http://127.0.0.1:4000
