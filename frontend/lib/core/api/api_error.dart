import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/auth/auth_controller.dart';
import 'api_client.dart';
import 'api_response.dart';

/// 业务码约定（与后端 utils/response.js 对齐）
class BizCode {
  /// 通用错误
  static const int fail = 1;
  /// 未登录 / token 失效
  static const int unauthorized = 401;
  /// 无权限
  static const int forbidden = 403;
  /// 资源不存在
  static const int notFound = 404;
  /// 后端未绑定伴侣
  static const int needBind = 4001;
}

/// 把任意异常归一为对用户友好的中文提示
String errorText(Object e) {
  if (e is BizException) {
    return e.message.isNotEmpty ? e.message : '操作失败';
  }
  if (e is DioException) {
    // 优先用后端业务错误
    final inner = e.error;
    if (inner is BizException) {
      return inner.message.isNotEmpty ? inner.message : '操作失败';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return '网络超时，请检查网络后重试';
    }
    if (e.type == DioExceptionType.connectionError) {
      return '网络连接失败，请检查网络';
    }
    if (e.type == DioExceptionType.cancel) {
      return '请求已取消';
    }
    if (e.response != null) {
      final code = e.response!.statusCode ?? 0;
      if (code == 401) return '登录已过期，请重新登录';
      if (code == 403) return '没有权限执行此操作';
      if (code == 404) return '资源不存在';
      if (code >= 500) return '服务器开小差了，请稍后再试';
      return '请求失败（$code）';
    }
    return '网络异常，请稍后再试';
  }
  final s = e.toString();
  if (s == 'null' || s.isEmpty) return '操作失败';
  return s;
}

/// 集中显示错误提示
/// - [title] 默认 "操作失败"
/// - 401 会自动清空 token、登出并跳到 /login
void showError(Object e, {String? title, bool autoHandle401 = true}) {
  if (autoHandle401) {
    if (e is DioException && e.response?.statusCode == 401) {
      _handleUnauthorized();
      return;
    }
    if (e is BizException && e.code == BizCode.unauthorized) {
      _handleUnauthorized();
      return;
    }
  }
  Get.snackbar(
    title ?? '操作失败',
    errorText(e),
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
    backgroundColor: Colors.black87,
    colorText: Colors.white,
    borderRadius: 12,
  );
}

void _handleUnauthorized() {
  if (Get.currentRoute == '/login') return;
  ApiClient.clearToken();
  if (Get.isRegistered<AuthController>()) {
    Get.find<AuthController>().logout();
  } else {
    Get.offAllNamed('/login');
  }
  Get.snackbar(
    '提示',
    '登录已过期，请重新登录',
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
  );
}
