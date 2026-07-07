# 后端 · 双人时光

Node.js 18 + Express + Sequelize + Socket.io + MySQL 8.0

## 启动

```bash
# 1. 起 MySQL（项目根目录）
docker compose up -d

# 2. 装依赖
npm install

# 3. 配 .env
cp .env.example .env
# 按需修改密码/JWT 等

# 4. 启动
npm run dev
```

监听 `http://0.0.0.0:3000`。

## 目录

```
src/
├── config/         # 配置 & Sequelize
├── controllers/    # 业务控制器（薄）
├── middleware/     # 鉴权 / 上传 / 错误处理
├── models/         # Sequelize 模型
├── routes/         # 路由
├── services/       # 服务层（消息、统计等）
├── sockets/        # Socket.io
└── utils/          # 工具
```

## 接口前缀：`/api`

| 模块 | 路径 | 说明 |
| --- | --- | --- |
| 健康 | `GET /health` | 心跳 |
| 认证 | `POST /auth/register` `POST /auth/login` `POST /auth/wx-login` `GET /auth/me` `PUT /auth/me` | 注册/登录/微信登录/我的 |
| 情侣 | `POST /couple/invite` `POST /couple/bind` `POST /couple/unbind` `GET /couple/info` `GET /couple/members` | 邀请/绑定/解绑/资料 |
| 行程 | `GET /schedules` `GET /schedules/today` `GET /schedules/calendar` `GET/POST/PUT/DELETE /schedules[/:id]` | CRUD + 日历 |
| 素材 | `GET /media` `POST /media` `POST /media/video` `PUT/DELETE /media/:id` `GET /media/group-by-schedule` | 上传/管理 |
| Todo | `GET /todos` `GET /todos/stats` `GET/POST/PUT/DELETE /todos[/:id]` | CRUD + 统计 |
| 统计 | `GET /stats/overview` | 首页概览 |
| 消息 | `GET /messages` `GET /messages/unread-count` `PUT /messages/read-all` `PUT /messages/:id/read` | 通知中心 |

## 统一返回结构

```json
{ "code": 0, "msg": "success", "data": {} }
```

- `code=0` 成功；`code!=0` 失败
- 所有需要鉴权接口：`Authorization: Bearer <token>`

## Socket 事件

连接：`io({ auth: { token } })`

- `schedule_update` `{ action, data|id }`
- `media_update`    `{ action, data|id }`
- `todo_update`     `{ action, data|id }`
- `message_push`    `{ ...消息DTO }`
- `bind_couple` 绑定后客户端发 `socket.emit('bind_couple', coupleId)`

## 静态资源

`/uploads/...` 暴露 `backend/uploads/` 目录下的图片视频。

## 数据库

`backend/sql/init.sql` 在 docker-compose 启动 MySQL 时自动执行。
生产环境可手动 `mysql -uroot -p < init.sql`。
