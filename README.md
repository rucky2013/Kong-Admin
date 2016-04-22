# 前言

该小项目主要是做 Kong 的一个代理。

- Kong 是用于实现 API Gateway 的一个东西，可以用于做微服务等，具体知识：[点这里](https://getkong.org/) 。

官方并没有实现一个 Dashboard，添加 api 的时候 使用 curl 则比较辛苦，所以做了这样一个代理小项目。虽然有一些别人的 DashBoard 的实现，但是感觉他们不怎么再维护了，自己用的时候感觉也有些 bug，所以想想干脆自己重新造轮子。

# Kong DashBoard 原理

这里主要是利用 kong 来帮我们查找数据，也就是说：该项目发请求到 kong 的 api 中，kong 帮我们查找 cassandra 数据库数据。当然，也可以直接利用 openResty 连 cassandra 数据库（这里没这样做）。

# 运行

1. 首先安装好 oepnResty，由于有登录的功能，所以需要安装 Redis，帐号密码自己设置，代码没有做加密。
2. 加入 [lua-resty-http](https://github.com/pintsized/lua-resty-http) 和 [lua-resty-template](https://github.com/bungle/lua-resty-template) 的支持。即把对应的 lua 文件加入到 /openresty/lualib/resty 中即可。
3. 使用 conf 目录下的 nginx.conf ，即跑 nginx 的时候指定该文件。指定好目录，例如： `./nginx -p /Users/yunxin/githubProject/myPro/Kong-Admin -c /Users/yunxin/githubProject/myPro/Kong-Admin/conf/nginx.conf`

图示：

![KongAPI1](http://7xrzlm.com1.z0.glb.clouddn.com/kongapi.png?imageMogr2/thumbnail/!25p)

![KongAPI1](http://7xrzlm.com1.z0.glb.clouddn.com/kongapi1.png?imageMogr2/thumbnail/!25p)

# openResty

oepnResty 基于 nginx + lua ，是处理高并发的利器。由于相当于个小工具类，所以这里其实使用 node，java 等都是可以的，个人主要是为了学习接触下 openResty，所以用这个技术来做。

PS：

这些代码，结构 只是 openResty 的皮毛，既没有涉及缓存，也没有涉及 DB，主要是 做 Kong 的 Dashboard 不需要这些。这里用到的主要东西有：

- cjson
- http
- template
- redis







