import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/utils/video_meta.dart';
import '../models/media_model.dart';

class MediaRepository {
  final ApiClient _api = ApiClient();

  Future<List<MediaItem>> list({
    int? scheduleId,
    String type = 'all', // all / image / video / star
  }) async {
    final list = await _api.get<List<dynamic>>(
      '/api/media',
      query: {
        if (scheduleId != null) 'scheduleId': scheduleId,
        'type': type,
      },
      parse: (d) => d as List<dynamic>,
    );
    return list.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MediaGroup>> groupBySchedule({String type = 'all'}) async {
    final list = await _api.get<List<dynamic>>(
      '/api/media/group-by-schedule',
      query: {'type': type},
      parse: (d) => d as List<dynamic>,
    );
    return list
        .map((e) => MediaGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 跨平台上传：传 XFile
  /// - 对视频会自动提取 duration/width/height 一并提交
  /// - [onProgress] (sent, total) 用于驱动 UI 进度条
  Future<MediaItem> upload({
    required XFile file,
    int? scheduleId,
    String? remark,
    String? mediaType,
    VideoMeta? videoMeta,
    void Function(int sent, int total)? onProgress,
  }) async {
    final path = mediaType == 'video' ? '/api/media/video' : '/api/media';
    final bytes = await file.readAsBytes();
    final j = await _api.uploadBytes<Map<String, dynamic>>(
      path,
      bytes: bytes,
      filename: file.name,
      mimeType: file.mimeType,
      extra: {
        if (scheduleId != null) 'scheduleId': scheduleId,
        if (remark != null) 'remark': remark,
        if (videoMeta != null) ...videoMeta.toJson(),
      },
      onSendProgress: onProgress,
      parse: (d) => d as Map<String, dynamic>,
    );
    return MediaItem.fromJson(j);
  }

  /// 跨平台批量上传：传 XFile 列表（图片/视频可混合）
  /// - 视频会提取 duration/width/height，按顺序打包成 JSON 字符串发给后端
  /// - [onProgress] (sent, total) 用于驱动 UI 进度条
  Future<List<MediaItem>> uploadBatch({
    required List<XFile> files,
    int? scheduleId,
    String? remark,
    List<VideoMeta>? videoMetas,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (files.isEmpty) return [];
    final items = <({List<int> bytes, String filename, String? mimeType})>[];
    for (final f in files) {
      items.add((
        bytes: await f.readAsBytes(),
        filename: f.name,
        mimeType: f.mimeType,
      ));
    }
    // 拍齐元数据数组（图片填 empty 占位）
    final metaList = <Map<String, dynamic>>[];
    for (var i = 0; i < files.length; i++) {
      final f = files[i];
      if (isVideoFile(f)) {
        metaList.add((videoMetas != null && i < videoMetas.length
                ? videoMetas[i]
                : VideoMeta.empty)
            .toJson());
      } else {
        metaList.add(VideoMeta.empty.toJson());
      }
    }
    final list = await _api.uploadBytesList<List<dynamic>>(
      '/api/media/batch',
      files: items,
      extra: {
        if (scheduleId != null) 'scheduleId': scheduleId,
        if (remark != null) 'remark': remark,
        'metadata': jsonEncode(metaList),
      },
      onSendProgress: onProgress,
      parse: (d) => d as List<dynamic>,
    );
    return list
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MediaItem> update(int id, Map<String, dynamic> patch) async {
    final j = await _api.put<Map<String, dynamic>>(
      '/api/media/$id',
      data: patch,
      parse: (d) => d as Map<String, dynamic>,
    );
    return MediaItem.fromJson(j);
  }

  Future<void> remove(int id) async {
    await _api.delete<Map<String, dynamic>>(
      '/api/media/$id',
      parse: (_) => <String, dynamic>{},
    );
  }
}
