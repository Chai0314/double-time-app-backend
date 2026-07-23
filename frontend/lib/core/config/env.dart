/// 全局环境配置
/// 修改这里的 baseUrl 切换不同环境
class Env {
  /// API 基础地址（同时也是静态资源 base）
  /// 部署在阿里云，使用 Nginx 反代到 /double-time-app-backend-api/
  static const String apiBaseUrl =
      'http://chaibinfeng.xyz/double-time-app-backend-api';

  /// WebSocket 地址（不带 path）
  static const String socketUrl = 'http://socket.chaibinfeng.xyz';

  /// 静态资源 base
  static String get mediaBase => apiBaseUrl;

  /// 应用名
  static const String appName = '双人时光';

  /// 主题色（与原型保持一致）
  static const int primaryColorValue = 0xFFFF8C9E;
}
