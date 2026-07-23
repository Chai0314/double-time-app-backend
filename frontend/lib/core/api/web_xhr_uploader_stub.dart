/// 非 Web 平台的 stub 实现。
/// 实际不会执行（调用方已用 kIsWeb 守门），
/// 仅用于在 native 编译时不报 MissingPluginException 之类的链接错误。
class WebXhrUploader {
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
    throw UnsupportedError('WebXhrUploader 仅在 Web 平台可用');
  }

  static Future<Map<String, dynamic>> uploadMultiple({
    required String url,
    required List<({List<int> bytes, String filename, String? mimeType})> files,
    String fieldName = 'files',
    Map<String, dynamic>? extra,
    String? token,
    void Function(int sent, int total)? onProgress,
  }) async {
    throw UnsupportedError('WebXhrUploader 仅在 Web 平台可用');
  }
}
