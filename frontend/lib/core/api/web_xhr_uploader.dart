/// 跨平台封装：Web 走 XMLHttpRequest，native 走 dart:io
///
/// 用条件导入实现：Web 编译时链接 web 实现，否则链接 stub。
/// stub 实际上不会被调用（api_client.dart 已用 kIsWeb 守门），
/// 但必须存在以便非 Web 平台可以编译通过。
library;

export 'web_xhr_uploader_stub.dart'
    if (dart.library.html) 'web_xhr_uploader_web.dart';
