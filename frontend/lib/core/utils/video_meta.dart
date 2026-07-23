import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// 视频元数据：时长 + 宽高
class VideoMeta {
  final int durationMs;
  final int width;
  final int height;
  const VideoMeta({
    required this.durationMs,
    required this.width,
    required this.height,
  });

  /// JSON 序列化（用于上传时传给后端）
  /// - duration 用秒（向上取整，避免太短视频显示 0:00）
  /// - width/height 是像素
  Map<String, dynamic> toJson() => {
        'duration': (durationMs / 1000).ceil(),
        'width': width,
        'height': height,
      };

  static const empty = VideoMeta(durationMs: 0, width: 0, height: 0);
}

/// 从 XFile 中提取视频元数据
/// - 通过 VideoPlayerController.initialize() 拿到真实时长与原始分辨率
/// - native 用 .file() 直读本地文件；web 用 .networkUrl() 读取 blob URL
/// - 失败返回 null（调用方应回退到 empty）
Future<VideoMeta?> extractVideoMeta(XFile file) async {
  VideoPlayerController? c;
  try {
    if (kIsWeb) {
      // web 上 XFile.path 通常是 blob: URL，可以直接喂给 networkUrl
      c = VideoPlayerController.networkUrl(Uri.parse(file.path));
    } else {
      c = VideoPlayerController.file(File(file.path));
    }
    await c.initialize();
    final dur = c.value.duration;
    final size = c.value.size;
    return VideoMeta(
      durationMs: dur.inMilliseconds,
      width: size.width.toInt(),
      height: size.height.toInt(),
    );
  } catch (_) {
    return null;
  } finally {
    await c?.dispose();
  }
}

/// 是否为视频文件
bool isVideoFile(XFile f) {
  final mime = (f.mimeType ?? '').toLowerCase();
  if (mime.startsWith('video/')) return true;
  final name = f.name.toLowerCase();
  return name.endsWith('.mp4') ||
      name.endsWith('.mov') ||
      name.endsWith('.m4v') ||
      name.endsWith('.webm') ||
      name.endsWith('.3gp');
}
