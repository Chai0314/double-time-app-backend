import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html';

Future<void> copyToClipboard(String text) async {
  // 异步 Clipboard API 仅在安全上下文（HTTPS / localhost）下可用
  // 在 file:// 或 http://ip:port 场景下 navigator.clipboard 为 null，
  // 此时必须用 execCommand + 临时 textarea 回退
  bool hasAsync = false;
  try {
    hasAsync = window.navigator.clipboard != null;
  } catch (_) {
    // clipboard 属性不存在，回退到 execCommand
  }
  if (hasAsync) {
    try {
      await window.navigator.clipboard!.writeText(text);
      return;
    } catch (_) {
      // 异步 API 调用失败，尝试回退
    }
  }

  // 回退：execCommand 需要 textarea 在 document 中且被选中
  final textarea = TextAreaElement()
    ..value = text
    ..style.position = 'fixed'
    ..style.top = '0'
    ..style.left = '0'
    ..style.width = '1px'
    ..style.height = '1px'
    ..style.padding = '0'
    ..style.border = 'none'
    ..style.outline = 'none'
    ..style.opacity = '0';
  document.body?.append(textarea);
  textarea.focus();
  textarea.select();
  final ok = document.execCommand('copy');
  textarea.remove();
  if (!ok) {
    throw Exception('复制失败，请手动复制');
  }
}
