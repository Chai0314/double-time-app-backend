# 双人时光 · 情侣/夫妻空间时间管理 App

> 产品定位：专为情侣、夫妻打造的双人专属时间规划 + 行程共享 + 素材沉淀 + 任务协同工具。

## 一、整体技术栈

| 层 | 选型 | 说明 |
| --- | --- | --- |
| 前端 | **Flutter 3.22+** | 一套代码 Android / iOS / 微信小程序 |
| 状态管理 | GetX | 轻量极速 |
| 网络 | Dio + 拦截器 | 统一 token、异常处理 |
| 本地缓存 | Hive | 用户信息、日程本地缓存 |
| 日历 | table_calendar | 日/周/月视图 |
| 图表 | fl_chart | 完成率/优先级/分工分析 |
| 实时 | socket_io_client | 双人实时同步 |
| 后端 | **Node.js 18 LTS + Express** | 文件处理强、异步好、阿里云低配机也跑得动 |
| ORM | Sequelize 6 | 表结构、约束、关联 |
| 数据库 | **MySQL 8.0** | utf8mb4，支持 emoji |
| 实时 | Socket.io | 行程 / 素材 / Todo / 消息 实时广播 |
| 文件 | multer | 图片/视频上传 |
| 鉴权 | JWT | 登录、情侣关系校验 |
| 跨域 | cors | H5 / 小程序调试方便 |
| 进程守护 | PM2 | 上线部署（部署阶段使用） |
| 反向代理 | Nginx | HTTPS、静态资源（部署阶段使用） |

## 二、目录结构

```
double-time-app/
├── docker-compose.yml         # 一键起 MySQL 8.0
├── backend/                   # Node.js 后端
│   ├── sql/init.sql           # 建表脚本
│   ├── src/
│   │   ├── config/            # 配置（DB、Server、JWT、Upload）
│   │   ├── controllers/       # 业务控制器
│   │   ├── middleware/        # 鉴权、统一异常
│   │   ├── models/            # Sequelize 模型
│   │   ├── routes/            # 路由
│   │   ├── services/          # 业务服务层
│   │   ├── sockets/           # Socket.io 事件
│   │   ├── utils/             # 工具
│   │   ├── validators/        # 入参校验
│   │   └── app.js
│   ├── uploads/               # 静态资源
│   ├── .env.example
│   ├── package.json
│   └── server.js
├── frontend/                  # Flutter 工程
│   ├── lib/
│   │   ├── core/              # API/常量/主题/工具
│   │   ├── data/              # models / repositories
│   │   ├── modules/           # 业务模块（auth/home/schedule/todo/album/profile/notifications）
│   │   ├── routes/            # 路由
│   │   ├── widgets/           # 通用组件
│   │   └── main.dart
│   └── pubspec.yaml
├── couple-space/              # 产品原型（HTML mockup，不参与编译）
└── README.md
```

## 三、本地开发顺序

### 1. 起数据库（两种选一种）

**A. 走 SQLite（推荐·零依赖）**

直接用 `backend/.env` 默认配置即可（`DB_DRIVER=sqlite`），文件落在 `backend/data/couple_space.sqlite`，启动时自动建表。

**B. 走 MySQL（更接近生产）**

```bash
cd double-time-app
docker compose up -d
# 等 10-30 秒，健康检查通过
docker compose ps
```

然后改 `backend/.env`：
```
DB_DRIVER=mysql
DB_HOST=127.0.0.1
DB_USER=couple
DB_PASSWORD=couple_pwd
```

### 2. 起后端

```bash
cd backend
cp .env.example .env       # 已默认 sqlite，可直接用
npm install
npm run dev                # nodemon 热更
# 默认监听 0.0.0.0:3000
```

### 3. 起前端（Flutter）

```bash
cd frontend
flutter pub get
flutter run -d <device-id>   # Android / iOS / Chrome 任选
```

> 兼容性提示：Flutter 端通过 `lib/core/config/env.dart` 配置 `API_BASE_URL`。
> - Android 模拟器：`http://127.0.0.1:3000`
> - iOS 模拟器：`http://127.0.0.1:3000`
> - 真机 / 小程序：填局域网 IP（如 `http://192.168.1.x:3000`），并且后端 CORS 已放行

## 四、已实现功能（V1.0 核心）

- 用户：账号 + 微信授权登录、JWT 鉴权
- 绑定：邀请码 / 账号搜索绑定、解除绑定
- 行程：CRUD、分类、提醒、月/日视图、归档
- 相册：图片/视频上传、绑定行程、精选、按行程/时间筛选
- Todo：CRUD、优先级、执行人、状态流转、按优先级排序
- 统计：完成率、本月行程、双方分工
- 消息通知：行程/任务/绑定/素材动态
- 实时：Socket.io 广播 `schedule_update` / `media_update` / `todo_update` / `message_push`

## 五、后续规划（不在本轮）

- 部署：阿里云 ECS + Nginx + PM2 + Let's Encrypt
- 小程序：Flutter 编译为微信小程序
- 推送：小程序订阅消息 / App 推送
- 高级：复盘、预算、导出、时光日志
