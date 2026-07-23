# 情侣夫妻时空管理App｜Flutter \+ 阿里云服务器 全套技术实现方案

## 一、整体技术选型结论（最终定稿，直接开发）

### 1\. 前端技术栈（固定）

**Flutter 3\.22\+**

- 支持：Android App / iOS App / 微信小程序（借助Flutter小程序编译方案）

- 优势：一套代码三端跑，极大降低开发成本

- 适配项目：日历行程、时间轴、相册、清单、图表统计、实时同步页面

### 2\. 后端技术栈（我给你最优推荐，适配你的阿里云单机服务器）

**最终推荐：Node\.js \+ Express \+ MySQL8\.0**

**不推荐Java/Go/Python的原因（非常关键）**

- Java：太重、阿里云低配服务器卡顿、部署复杂、开发慢（个人项目完全没必要）

- Go：开发效率低、业务 CURD 繁琐、不适合快速迭代产品

- Python：异步弱、高并发差、图片视频上传容易卡死

**Node\.js Express 是情侣类App最优解：**

- 极强的文件处理能力（图片/视频上传、裁剪、存储）

- 天然异步，适合双人实时同步、消息推送

- 轻量、阿里云低配服务器即可流畅跑

- 开发速度最快，适配你的所有业务：行程、待办、相册、双人绑定

### 3\. 服务器与部署

自有 **阿里云ECS**（CentOS7\.9 / Ubuntu20\.04）

- 单机部署即可，无需负载均衡（用户量级匹配）

- 文件存储：阿里云ECS本地存储 \+ 后续可无缝升级OSS

- 域名 \+ HTTPS 全站加密（小程序强制要求）

### 4\. 整体架构模式

**客户端\(Flutter\) ⟷ 后端API\(Node\) ⟷ MySQL ⟷ 阿里云文件存储**

长连接 \+ 短连接结合：

- 普通列表、查询、表单：HTTP接口

- 双人实时同步、消息提醒、在线状态：Socket\.io 长连接

---

## 二、全套技术栈明细（可直接写进开发文档）

### 1\. 前端 Flutter 技术栈

- 框架：Flutter 3\.22 Stable

- 状态管理：GetX（轻量、极速、适合社交/日程类App）

- 网络：Dio \+ 拦截器（统一token、异常处理）

- 本地存储：Hive（存储用户信息、本地缓存日程）

- 日历组件：table\_calendar（日/周/月视图完美适配）

- 相册/媒体：image\_picker \+ video\_player

- 图表分析：fl\_chart（完成待办数据饼图、折线图）

- 实时通讯：socket\_io\_client（双人实时同步）

- 权限管理：permission\_handler

- 打包：Android APK / iOS IPA / 微信小程序编译

### 2\. 后端 Node\.js Express 技术栈

- 运行环境：Node 18\.x LTS（稳定版）

- 框架：Express

- 数据库：MySQL 8\.0

- ORM：Sequelize（表结构管理、字段约束、关联关系）

- 实时通讯：Socket\.io（双人数据实时同步、消息推送）

- 文件上传：multer（图片/视频分片上传）

- 鉴权：JWT 令牌登录

- 跨域：cors 全局处理

- 定时任务：node\-schedule（行程提醒、待办到期提醒）

- 日志：winston 日志收集

### 3\. 服务器运维 \& 部署

- 系统：Ubuntu 20\.04 / CentOS 7\.9

- 进程守护：PM2（后台永久运行、崩溃自动重启）

- 反向代理：Nginx

- 证书：Let’s Encrypt 免费HTTPS

- 数据库运维：MySQL开机自启、定时备份

---

## 三、核心业务架构设计（适配你的全部功能）

### 1\. 业务模块拆分（前后端完全对应）

1\. 用户模块：登录、微信授权、情侣绑定、解绑

2\. 行程模块：新建/编辑/日历视图/重复行程/提醒

3\. 素材相册模块：图片视频上传、行程绑定、双人共享、删除权限控制

4\. Todo任务模块：待办分级、优先级、分工、逾期判断

5\. 数据统计模块：完成率、双人分工数据、图表统计

6\. 消息推送模块：Socket实时通知、系统提醒

### 2\. 双人实时同步核心机制（关键技术点）

所有共享数据（行程/相册/任务）采用：**数据库存储 \+ Socket实时广播**

- A用户修改行程 \-\> 后端入库 \-\> Socket广播给绑定情侣B

- B用户手机实时刷新数据，无需下拉刷新

- 离线机制：用户上线自动拉取最新增量数据

### 3\. 素材文件存储方案（适配阿里云服务器）

**初期（免费、够用）：ECS本地存储 \+ Nginx静态资源访问**

**后期扩容：无缝切换阿里云OSS**（代码无需大改）

文件规则：

- 图片压缩存储，减少服务器压力

- 所有文件绑定行程ID、用户ID

- 双人权限控制：仅绑定情侣可访问资源链接

---

## 四、数据库设计核心表结构（精简关键表）

只列出核心表，开发可直接建表

### 1\. 用户表 user

- id、nickname、avatar、openid\(微信\)、phone、create\_time

- couple\_id：绑定情侣用户ID（核心关联字段）

- status：绑定状态

### 2\. 行程表 travel\_schedule

- id、user\_id、couple\_id、title、category、address、budget、remark

- start\_time、end\_time、repeat\_type

- status、remind\_time

### 3\. 素材相册表 travel\_media

- id、schedule\_id、user\_id、couple\_id

- media\_type\(image/video\)、media\_url、remark、is\_star

### 4\. 待办任务表 todo\_list

- id、user\_id、couple\_id、title、category、level\(优先级\)

- executor\_user\_id、deadline、status、schedule\_id

### 5\. 消息通知表 message

- id、receive\_user\_id、content、type、is\_read、create\_time

---

## 五、接口设计规范（统一前后端）

### 1\. 接口格式

统一返回结构：

```Plain Text
{
  "code":200,
  "msg":"success",
  "data":{}
}
```

### 2\. 鉴权方式

Header 携带 Token：Authorization: Bearer xxx

所有私密接口必须校验情侣绑定关系

### 3\. 实时Socket事件定义

- schedule\_update：行程新增/修改/删除

- media\_update：相册素材更新

- todo\_update：待办任务变更

- message\_push：新消息推送

---

## 六、阿里云服务器部署方案（完整上线流程）

### 1\. 服务器环境搭建

- 安装 Node18 \+ MySQL8\.0 \+ Nginx \+ PM2

- MySQL开启远程访问、定时备份

- 开放端口：80、443、3000\(Socket\)

### 2\. 项目部署结构

- 后端目录：/www/couple\-api

- 静态资源目录：/www/couple\-static（存放图片视频）

- PM2常驻启动，开机自启

### 3\. 小程序兼容处理

- Nginx配置HTTPS，满足小程序域名要求

- 小程序后台配置合法域名、socket域名

---

## 七、该技术方案的核心优势（适配你的项目）

- **最省服务器资源**：Node\+MySQL在阿里云低配机流畅运行，不卡顿

- **开发速度最快**：Flutter一套代码三端，后端CRUD极速开发

- **完美适配双人实时同步**：Socket\.io是情侣类App的最优方案

- **图片视频处理能力强**：Node天生适合文件上传、压缩、管理

- **可无缝迭代**：后期可加OSS、推送、会员、情感日记等功能

- **完全私有化部署**：数据全部在你自己阿里云服务器，隐私性极强

---

## 八、开发顺序建议

1\. 搭建后端环境 \+ 数据库建表

2\. 完成登录、情侣绑定核心逻辑

3\. 开发行程模块 \+ 日历页面

4\. 开发相册素材上传共享模块

5\. 开发Todo清单 \+ 数据分析

6\. 对接Socket实时同步、消息推送

7\. 整体联调、打包、小程序发布

> （注：部分内容可能由 AI 生成）
