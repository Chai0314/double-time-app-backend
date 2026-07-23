import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/socket_service.dart';
import '../../core/utils/video_meta.dart';
import '../../data/models/media_model.dart';
import '../../data/repositories/media_repository.dart';

/// 相册分类
/// - all   全部
/// - video 视频
/// - image 图片
/// - star  收藏
enum AlbumTab { all, video, image, star }

extension AlbumTabX on AlbumTab {
  String get apiValue {
    switch (this) {
      case AlbumTab.all:
        return 'all';
      case AlbumTab.video:
        return 'video';
      case AlbumTab.image:
        return 'image';
      case AlbumTab.star:
        return 'star';
    }
  }

  String get label {
    switch (this) {
      case AlbumTab.all:
        return '全部';
      case AlbumTab.video:
        return '视频';
      case AlbumTab.image:
        return '图片';
      case AlbumTab.star:
        return '收藏';
    }
  }
}

class AlbumController extends GetxController {
  final MediaRepository _repo = MediaRepository();

  final RxList<MediaGroup> groups = <MediaGroup>[].obs;
  final Rx<AlbumTab> currentTab = AlbumTab.all.obs;
  final RxBool loading = false.obs;

  /// 上传进度（驱动底部小进度条）
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs; // 0.0 ~ 1.0
  final RxString uploadLabel = ''.obs; // "正在上传 3/8 · 42%"
  final RxString uploadFileName = ''.obs; // 当前正在上传的文件名（可选显示）

  @override
  void onInit() {
    super.onInit();
    _bindSocket();
    refresh();
  }

  void _bindSocket() {
    SocketService().events.listen((e) {
      if (e.name == 'media_update') {
        refresh();
      }
    });
  }

  Future<void> refresh() async {
    loading.value = true;
    try {
      final list = await _repo.groupBySchedule(type: currentTab.value.apiValue);
      groups.assignAll(list);
    } catch (_) {} finally {
      loading.value = false;
    }
  }

  Future<void> switchTab(AlbumTab tab) async {
    if (currentTab.value == tab) return;
    currentTab.value = tab;
    await refresh();
  }

  Future<void> uploadMedia({
    required XFile file,
    int? scheduleId,
    String? remark,
    String? mediaType,
  }) async {
    VideoMeta? meta;
    if (mediaType == 'video' || isVideoFile(file)) {
      meta = await extractVideoMeta(file);
    }
    isUploading.value = true;
    uploadProgress.value = 0.0;
    uploadFileName.value = file.name;
    uploadLabel.value = '正在上传 1/1';
    try {
      await _repo.upload(
        file: file,
        scheduleId: scheduleId,
        remark: remark,
        mediaType: mediaType,
        videoMeta: meta,
        onProgress: (sent, total) {
          final p = total > 0 ? (sent / total).clamp(0.0, 1.0) : 0.0;
          uploadProgress.value = p;
          uploadLabel.value = total > 0
              ? '正在上传 1/1 · ${(p * 100).toInt()}%'
              : '正在上传 1/1';
        },
      );
      await refresh();
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
      uploadLabel.value = '';
      uploadFileName.value = '';
    }
  }

  /// 批量上传：图片/视频混合；返回成功上传的数量
  Future<int> uploadMediaBatch({
    required List<XFile> files,
    int? scheduleId,
    String? remark,
  }) async {
    if (files.isEmpty) return 0;
    final total = files.length;
    isUploading.value = true;
    uploadProgress.value = 0.0;
    uploadFileName.value = files.first.name;
    uploadLabel.value = '正在上传 1/$total';
    // 提前把每个视频的元数据并行抽出来（图片保持 empty；视频提取失败也用 empty）
    final metas = <VideoMeta>[];
    for (final f in files) {
      if (isVideoFile(f)) {
        metas.add(await extractVideoMeta(f) ?? VideoMeta.empty);
      } else {
        metas.add(VideoMeta.empty);
      }
    }
    int lastIdx = 0;
    try {
      final list = await _repo.uploadBatch(
        files: files,
        scheduleId: scheduleId,
        remark: remark,
        videoMetas: metas,
        onProgress: (sent, totalBytes) {
          final p = totalBytes > 0 ? (sent / totalBytes).clamp(0.0, 1.0) : 0.0;
          // 按文件大小估算当前上传到第几个（粗略，仅用于显示）
          final approxIdx =
              (p * total).floor().clamp(0, total - 1).toInt();
          if (approxIdx != lastIdx) {
            lastIdx = approxIdx;
            if (approxIdx < files.length) {
              uploadFileName.value = files[approxIdx].name;
            }
          }
          uploadProgress.value = p;
          uploadLabel.value = totalBytes > 0
              ? '正在上传 ${approxIdx + 1}/$total · ${(p * 100).toInt()}%'
              : '正在上传 $total 个文件';
        },
      );
      await refresh();
      return list.length;
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
      uploadLabel.value = '';
      uploadFileName.value = '';
    }
  }

  Future<void> toggleStar(MediaItem m) async {
    await _repo.update(m.id, {'isStar': m.isStar == 1 ? 0 : 1});
    await refresh();
  }

  Future<void> deleteMedia(int id) async {
    await _repo.remove(id);
    await refresh();
  }
}
