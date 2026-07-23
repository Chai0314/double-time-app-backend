/// 接口返回统一结构
class ApiResponse<T> {
  final int code;
  final String msg;
  final T? data;

  ApiResponse({required this.code, required this.msg, this.data});

  bool get isOk => code == 0;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw) parse,
  ) {
    return ApiResponse(
      code: (json['code'] ?? 1) as int,
      msg: (json['msg'] ?? '') as String,
      data: json['data'] == null ? null : parse(json['data']),
    );
  }
}

/// 后端业务异常
class BizException implements Exception {
  /// 业务错误码：后端约定 0=成功，1=通用错误，其它自定义
  final int code;
  /// 后端返回的 msg（已是对用户友好文案）
  final String message;
  BizException(this.code, this.message);

  @override
  String toString() => message;
}
