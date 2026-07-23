import 'package:intl/intl.dart';

import '../../core/config/env.dart';
import 'schedule_model.dart' show UserBrief;

class MediaItem {
  final int id;
  final int coupleId;
  final int? scheduleId;
  final int uploaderId;
  final String mediaType; // image / video
  final String url;
  final String thumbUrl;
  final int duration;
  final int size;
  final String remark;
  final int isStar;
  final DateTime? takenAt;
  final DateTime? createdAt;
  final UserBrief? uploader;
  final ScheduleBrief? schedule;

  MediaItem({
    required this.id,
    required this.coupleId,
    this.scheduleId,
    required this.uploaderId,
    required this.mediaType,
    required this.url,
    required this.thumbUrl,
    required this.duration,
    required this.size,
    required this.remark,
    required this.isStar,
    this.takenAt,
    this.createdAt,
    this.uploader,
    this.schedule,
  });

  factory MediaItem.fromJson(Map<String, dynamic> j) => MediaItem(
        id: (j['id'] as num).toInt(),
        coupleId: (j['coupleId'] as num).toInt(),
        scheduleId:
            j['scheduleId'] == null ? null : (j['scheduleId'] as num).toInt(),
        uploaderId: (j['uploaderId'] as num).toInt(),
        mediaType: (j['mediaType'] ?? 'image') as String,
        url: (j['url'] ?? '') as String,
        thumbUrl: (j['thumbUrl'] ?? '') as String,
        duration: (j['duration'] ?? 0) as int,
        size: (j['size'] ?? 0) as int,
        remark: (j['remark'] ?? '') as String,
        isStar: (j['isStar'] ?? 0) as int,
        takenAt: j['takenAt'] == null ? null : DateTime.tryParse(j['takenAt']),
        createdAt:
            j['createdAt'] == null ? null : DateTime.tryParse(j['createdAt']),
        uploader: j['uploader'] == null
            ? null
            : UserBrief.fromJson(j['uploader'] as Map<String, dynamic>),
        schedule: j['schedule'] == null
            ? null
            : ScheduleBrief.fromJson(j['schedule'] as Map<String, dynamic>),
      );

  String get fullUrl =>
      url.startsWith('http') ? url : '${Env.apiBaseUrl}$url';

  String get fullThumbUrl {
    final raw = (thumbUrl.isNotEmpty ? thumbUrl : url);
    return raw.startsWith('http') ? raw : '${Env.apiBaseUrl}$raw';
  }

  String get dateText {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final c = createdAt!;
    // 跨年：显示 yyyy-MM-dd
    if (c.year != now.year) {
      return DateFormat('yyyy-MM-dd').format(c);
    }
    // 今年：MM-dd HH:mm
    return DateFormat('MM-dd HH:mm').format(c);
  }
}

class ScheduleBrief {
  final int id;
  final String title;
  ScheduleBrief({required this.id, required this.title});
  factory ScheduleBrief.fromJson(Map<String, dynamic> j) => ScheduleBrief(
        id: (j['id'] as num).toInt(),
        title: (j['title'] ?? '') as String,
      );
}

class MediaGroup {
  final int? scheduleId;
  final String scheduleTitle;
  final DateTime? scheduleDate;
  final List<MediaItem> items;

  MediaGroup({
    this.scheduleId,
    required this.scheduleTitle,
    this.scheduleDate,
    required this.items,
  });

  factory MediaGroup.fromJson(Map<String, dynamic> j) => MediaGroup(
        scheduleId:
            j['scheduleId'] == null ? null : (j['scheduleId'] as num).toInt(),
        scheduleTitle: (j['scheduleTitle'] ?? '未分类') as String,
        scheduleDate: j['scheduleDate'] == null
            ? null
            : DateTime.tryParse(j['scheduleDate']),
        items: ((j['items'] ?? []) as List)
            .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
