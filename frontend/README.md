# 前端 · 双人时光 Flutter App

## 启动

```bash
# 1. 先把脚手架补齐（一次性）
flutter create . --project-name couple_space

# 2. 装依赖
flutter pub get

# 3. 跑
flutter run
```

## 配置后端地址

`lib/core/config/env.dart`：

```dart
// Android 模拟器 → 宿主机
static const String apiBaseUrl = 'http://127.0.0.1:3000';
// iOS 模拟器
// static const String apiBaseUrl = 'http://127.0.0.1:3000';
// 真机 / 局域网
// static const String apiBaseUrl = 'http://192.168.1.100:3000';
```

## 目录

```
lib/
├── core/              # API/配置/主题/工具
│   ├── api/           # ApiClient、SocketService
│   ├── config/        # Env
│   └── theme/         # AppTheme
├── data/
│   ├── models/        # User、Schedule、Todo、Media、Stats
│   └── repositories/  # 仓库层
├── modules/
│   ├── auth/          # 登录/注册
│   ├── couple/        # 情侣绑定
│   ├── home/          # 首页
│   ├── schedule/      # 行程
│   ├── todo/          # 待办
│   ├── album/         # 相册
│   ├── profile/       # 个人
│   └── notifications/ # 通知
└── routes/            # GetX 路由
```

## 兼容

- Android 5.0+ / iOS 12.0+
- 屏幕宽度 320 ~ 414 设计
- 暗黑模式未做（保留扩展点）
