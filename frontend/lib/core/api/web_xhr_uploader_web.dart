// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'api_response.dart';

/// Web 平台：直接用 XMLHttpRequest 发送 multipart/form-data。
///
/// 为什么不用 dio？
/// - dio 在 Web 上封装的是 `XMLHttpRequest`，但对 multipart 的预检/CORS 行为
///   不可控：dio 会主动 set `Content-Type: multipart/form-data` 触发 CORS 预检，
///   一旦后端/Nginx 响应头里 `Access-Control-Allow-Headers` 没把
///   `Authorization, Content-Type` 都放行，浏览器就会拦掉。
/// - 直接走 XHR，可以更精细地控制：
///     * 不手动设 `Content-Type`（让浏览器自动加 boundary，避免与 dio 重复）
///     * `xhr.withCredentials = false`（与 `cors({credentials:true})` 配合时，
///       `Access-Control-Allow-Origin` 不能是 `*`，由浏览器处理 CORS 响应）
///     * `xhr.upload.onprogress` 拿到原生上传进度（dio 在 Web 上偶发不触发）
///
/// 实现用 `package:web` + `dart:js_interop`（Dart 3.4+ 推荐的现代写法，
/// 旧 `dart:html` 在新版本里同名类被替换为 JS interop 类型，不能直接构造）。
class WebXhrUploader {
  /// 单文件上传。返回后端原始响应 `{code, msg, data}`，由调用方做解包。
  static Future<Map<String, dynamic>> upload({
    required String url,
    required List<int> bytes,
    required String filename,
    String? mimeType,
    String fieldName = 'file',
    Map<String, dynamic>? extra,
    String? token,
    void Function(int sent, int total)? onProgress,
  }) async {
    final form = web.FormData();
    final blob = web.Blob(
      <JSAny>[Uint8List.fromList(bytes).toJS].toJS,
      web.BlobPropertyBag(type: mimeType ?? ''),
    );
    form.append(fieldName, blob, filename);
    if (extra != null) {
      extra.forEach((k, v) {
        if (v == null) return;
        form.append(k, v.toString().toJS);
      });
    }
    final raw = await _send(
      url: url,
      form: form,
      token: token,
      onProgress: onProgress,
    );
    return _decodeMap(raw);
  }

  /// 多文件批量上传。返回后端原始响应 `{code, msg, data}`。
  static Future<Map<String, dynamic>> uploadMultiple({
    required String url,
    required List<({List<int> bytes, String filename, String? mimeType})> files,
    String fieldName = 'files',
    Map<String, dynamic>? extra,
    String? token,
    void Function(int sent, int total)? onProgress,
  }) async {
    final form = web.FormData();
    for (final f in files) {
      final blob = web.Blob(
        <JSAny>[Uint8List.fromList(f.bytes).toJS].toJS,
        web.BlobPropertyBag(type: f.mimeType ?? ''),
      );
      form.append(fieldName, blob, f.filename);
    }
    if (extra != null) {
      extra.forEach((k, v) {
        if (v == null) return;
        form.append(k, v.toString().toJS);
      });
    }
    final raw = await _send(
      url: url,
      form: form,
      token: token,
      onProgress: onProgress,
    );
    return _decodeMap(raw);
  }

  static Future<String> _send({
    required String url,
    required web.FormData form,
    String? token,
    void Function(int sent, int total)? onProgress,
  }) async {
    final xhr = web.XMLHttpRequest();
    xhr.open('POST', url, true);
    xhr.withCredentials = false;
    if (token != null && token.isNotEmpty) {
      xhr.setRequestHeader('Authorization', 'Bearer $token');
    }
    // 不手动 setRequestHeader('Content-Type')，让浏览器自动加 boundary

    if (onProgress != null) {
      xhr.upload.onprogress = ((web.ProgressEvent e) {
        final loaded = e.loaded.toInt();
        final total = e.total.toInt();
        onProgress(loaded, total);
      }).toJS;
    }

    final completer = Completer<String>();
    xhr.onload = ((web.Event _) {
      final status = xhr.status;
      final body = xhr.responseText;
      // 0 表示跨域被浏览器拦截（CORS 失败时 status 拿不到，responseText 为空）
      if (status == 0 && body.isEmpty) {
        completer.completeError(BizException(
          0,
          '网络异常或被浏览器拦截（CORS），请检查服务端响应头',
        ));
        return;
      }
      if (status >= 200 && status < 300) {
        completer.complete(body);
      } else {
        completer.completeError(BizException(status, body));
      }
    }).toJS;
    xhr.onerror = ((web.Event _) {
      completer.completeError(BizException(
        0,
        '网络异常或被浏览器拦截（CORS），请检查服务端响应头',
      ));
    }).toJS;
    xhr.send(form);
    return completer.future;
  }

  static Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'code': -1, 'msg': '非预期响应', 'data': decoded};
  }
}
