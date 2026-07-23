import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:shared_preferences/shared_preferences.dart';

import '../../modules/auth/auth_controller.dart';
import '../config/env.dart';
import 'api_response.dart';
import 'web_xhr_uploader.dart';

/// Dio 单例 + 拦截器
class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio dio;
  static const _tokenKey = 'access_token';

  ApiClient._() {
    dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (s) => s != null && s < 500,
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 注入 token
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // 后端统一 {code,msg,data}
        final raw = response.data;
        if (raw is Map && raw['code'] != null && raw['code'] != 0) {
          // 业务错误：抛给上层
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: BizException(
                (raw['code'] as num).toInt(),
                (raw['msg'] ?? 'fail').toString(),
              ),
            ),
          );
        }
        handler.next(response);
      },
      onError: (e, handler) {
        // 401 / 业务码 401 → 清理 token 并跳登录
        final status = e.response?.statusCode;
        final inner = e.error;
        final isUnauthorized = status == 401 ||
            (inner is BizException && inner.code == 401);
        if (isUnauthorized) {
          // 异步触发，不阻塞当前错误传递
          _onUnauthorized();
        }
        handler.next(e);
      },
    ));
  }

  /// 401 全局处理：清 token + 调 AuthController.logout
  static void _onUnauthorized() {
    if (_unauthorizedHandled) return;
    _unauthorizedHandled = true;
    ApiClient.clearToken();
    // 用一个 microtask 跳路由，避免在 dio 拦截器里直接动 navigator
    Future.microtask(() {
      _unauthorizedHandled = false;
      // 已经在登录页就不重复弹
      final router = Get.currentRoute;
      if (router == '/login') return;
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
    });
  }

  static bool _unauthorizedHandled = false;

  /// 设置 token
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// 读取 token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// 清除 token
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// 统一 GET
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    final r = await dio.get(path, queryParameters: query);
    return _unwrap(r, parse);
  }

  /// 统一 POST
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    final r = await dio.post(path, data: data, queryParameters: query);
    return _unwrap(r, parse);
  }

  /// 统一 PUT
  Future<T> put<T>(
    String path, {
    dynamic data,
    required T Function(dynamic data) parse,
  }) async {
    final r = await dio.put(path, data: data);
    return _unwrap(r, parse);
  }

  /// 统一 DELETE
  Future<T> delete<T>(
    String path, {
    required T Function(dynamic data) parse,
  }) async {
    final r = await dio.delete(path);
    return _unwrap(r, parse);
  }

  /// 上传文件（native 平台，直接传路径）
  Future<T> upload<T>(
    String path, {
    required String filePath,
    String? fieldName,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) parse,
  }) async {
    final form = FormData.fromMap({
      fieldName ?? 'file': await MultipartFile.fromFile(filePath),
      if (extra != null) ...extra,
    });
    final r = await dio.post(
      path,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _unwrap(r, parse);
  }

  /// 上传文件（跨平台：通过字节流上传，web/native 都可用）
  /// - [mimeType] 显式指定文件的 MIME（如 "image/jpeg"），保证后端 multer
  ///   拿到正确的 mimetype。dio 内部会从 filename 推断，但 iOS/Web 上偶发
  ///   推断失败（HEIC/无后缀等），所以这里强制走 XFile.mimeType。
  /// - [onSendProgress] 用于驱动 UI 上的进度条；native 由 dio 透传，
  ///   web 走 [WebXhrUploader] 时由 XHR.upload.onprogress 回调。
  Future<T> uploadBytes<T>(
    String path, {
    required List<int> bytes,
    required String filename,
    String? mimeType,
    String? fieldName,
    Map<String, dynamic>? extra,
    void Function(int sent, int total)? onSendProgress,
    required T Function(dynamic data) parse,
  }) async {
    // Web 走原生 XHR，避免 dio 在 web 上对 multipart 预检/CORS 行为不可控
    if (kIsWeb) {
      final token = await getToken();
      final url = '${Env.apiBaseUrl}$path';
      final raw = await WebXhrUploader.upload(
        url: url,
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
        fieldName: fieldName ?? 'file',
        extra: extra,
        token: token,
        onProgress: onSendProgress,
      );
      return _unwrapFromMap(raw);
    }
    final form = FormData.fromMap({
      fieldName ?? 'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: _parseContentType(mimeType),
      ),
      if (extra != null) ...extra,
    });
    final r = await dio.post(
      path,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onSendProgress,
    );
    return _unwrap(r, parse);
  }

  /// 批量上传文件（一个字段名多文件），所有文件共用 extra 字段
  Future<T> uploadBytesList<T>(
    String path, {
    required List<({List<int> bytes, String filename, String? mimeType})> files,
    String fieldName = 'files',
    Map<String, dynamic>? extra,
    void Function(int sent, int total)? onSendProgress,
    required T Function(dynamic data) parse,
  }) async {
    // Web 走原生 XHR
    if (kIsWeb) {
      final token = await getToken();
      final url = '${Env.apiBaseUrl}$path';
      final raw = await WebXhrUploader.uploadMultiple(
        url: url,
        files: files,
        fieldName: fieldName,
        extra: extra,
        token: token,
        onProgress: onSendProgress,
      );
      // 复用 _unwrapFromMap：检查 code 并 parse(data)
      return _unwrapFromMapWithParse<T>(raw, parse);
    }
    final form = FormData.fromMap({
      fieldName: [
        for (final f in files)
          MultipartFile.fromBytes(
            f.bytes,
            filename: f.filename,
            contentType: _parseContentType(f.mimeType),
          ),
      ],
      if (extra != null) ...extra,
    });
    final r = await dio.post(
      path,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onSendProgress,
    );
    return _unwrap(r, parse);
  }

  /// 解析 ContentType：优先用显式 mimeType（来自 XFile.mimeType），
  /// 这样后端 multer 拿到的就是真实 mimetype，不会被 dio 推断走偏。
  /// mimeType 为空时返回 null，dio 会按 filename 后缀兜底。
  static MediaType? _parseContentType(String? mimeType) {
    if (mimeType == null || mimeType.isEmpty) return null;
    final parts = mimeType.split('/');
    if (parts.length != 2) return null;
    return MediaType(parts[0], parts[1]);
  }

  /// Web 路径下从 XHR 返回的 Map 走和 dio 一样的解包逻辑
  T _unwrapFromMap<T>(Map<String, dynamic> raw) {
    if (raw['code'] == 0) {
      // 与 _unwrap 保持一致：始终 parse(data)
      return (raw['data'] as dynamic) as T;
    }
    throw BizException(
      (raw['code'] as num?)?.toInt() ?? 500,
      (raw['msg'] ?? 'fail').toString(),
    );
  }

  /// 同 _unwrapFromMap，但用 parse 回调（与 dio._unwrap 行为对齐）
  T _unwrapFromMapWithParse<T>(
    Map<String, dynamic> raw,
    T Function(dynamic) parse,
  ) {
    if (raw['code'] == 0) {
      return parse(raw['data']);
    }
    throw BizException(
      (raw['code'] as num?)?.toInt() ?? 500,
      (raw['msg'] ?? 'fail').toString(),
    );
  }

  T _unwrap<T>(Response r, T Function(dynamic) parse) {
    final raw = r.data;
    if (raw is Map && raw['code'] == 0) {
      // 统一交由 parse 处理 data（可能为 null，如 DELETE 响应）
      return parse(raw['data']);
    }
    if (raw is Map && raw['code'] != null) {
      throw BizException(
        (raw['code'] as num).toInt(),
        (raw['msg'] ?? 'fail').toString(),
      );
    }
    throw BizException(500, '接口返回异常');
  }
}
