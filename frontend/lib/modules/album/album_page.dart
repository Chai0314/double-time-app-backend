import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../core/api/api_error.dart';
import '../../core/config/env.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/media_model.dart';
import 'album_controller.dart';

class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AlbumController());
    final picker = ImagePicker();
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('我们的甜蜜时光'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload, color: AppTheme.primary),
            onPressed: () => _showUploadSheet(picker, c),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const _TabBar(),
              Expanded(
                child: Obx(() {
                  if (c.loading.value && c.groups.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return RefreshIndicator(
                    onRefresh: c.refresh,
                    child: c.groups.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              _Empty(),
                            ],
                          )
                        : ListView(
                            children: [
                              const SizedBox(height: 8),
                              ...c.groups.map((g) => _Group(g: g)),
                              // 留出底部进度条的位置，避免遮挡最后一行
                              const SizedBox(height: 96),
                            ],
                          ),
                  );
                }),
              ),
            ],
          ),
          // 底部小进度块
          const Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: _UploadProgressBar(),
            ),
          ),
        ],
      ),
    );
  }

  /// 弹出底部操作表：选择图片来源（图片/视频/拍照）
  /// 点选后立即关闭 sheet，上传在后台跑，进度由 [AlbumController] 驱动
  /// 底部的 _UploadProgressBar 显示。
  Future<void> _showUploadSheet(ImagePicker picker, AlbumController c) async {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('上传素材',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('支持图片和视频',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
              _sheetItem(
                Icons.photo_library_outlined,
                '从相册选择（图片 / 视频，可多选）',
                () async {
                  Get.back(); // 立刻关闭 sheet
                  try {
                    final list = await picker.pickMultipleMedia(
                      imageQuality: 80,
                      maxWidth: 2048,
                    );
                    if (list.isEmpty) return;
                    final n = await c.uploadMediaBatch(files: list);
                    Get.snackbar(
                      '上传成功',
                      n == 1 ? '已上传 1 个素材' : '已上传 $n 个素材',
                    );
                  } catch (e) {
                    showError(e, title: '上传失败');
                  }
                },
              ),
              _sheetItem(
                Icons.photo_camera_outlined,
                '拍照',
                () async {
                  Get.back();
                  try {
                    final XFile? f = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (f == null) return;
                    await c.uploadMedia(file: f, mediaType: 'image');
                    Get.snackbar('上传成功', '图片已上传');
                  } catch (e) {
                    showError(e, title: '上传失败');
                  }
                },
              ),
              _sheetItem(
                Icons.videocam_outlined,
                '拍视频',
                () async {
                  Get.back();
                  try {
                    final XFile? f = await picker.pickVideo(
                      source: ImageSource.camera,
                      maxDuration: const Duration(minutes: 5),
                    );
                    if (f == null) return;
                    await c.uploadMedia(file: f, mediaType: 'video');
                    Get.snackbar('上传成功', '视频已上传');
                  } catch (e) {
                    showError(e, title: '上传失败');
                  }
                },
              ),
              _sheetItem(
                Icons.close,
                '取消',
                () => Get.back(),
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                  color: color ?? AppTheme.textPrimary,
                  fontSize: 15,
                )),
          ],
        ),
      ),
    );
  }
}

/// 底部小进度条
class _UploadProgressBar extends StatelessWidget {
  const _UploadProgressBar();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AlbumController>();
    return Obx(() {
      if (!c.isUploading.value) return const SizedBox.shrink();
      final p = c.uploadProgress.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: Colors.white,
          elevation: 6,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.uploadLabel.value.isEmpty
                                  ? '正在上传...'
                                  : c.uploadLabel.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${(p * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p,
                          minHeight: 4,
                          backgroundColor: const Color(0xFFEEEEEE),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AlbumController>();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Obx(() => Row(
            children: AlbumTab.values.map((t) {
              final active = c.currentTab.value == t;
              return Expanded(
                child: GestureDetector(
                  onTap: () => c.switchTab(t),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: active ? AppTheme.primary : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      t.label,
                      style: TextStyle(
                        color: active ? AppTheme.primary : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          )),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    final c = Get.find<AlbumController>();
    final tip = c.currentTab.value == AlbumTab.star
        ? '还没有收藏的素材，长按素材即可收藏'
        : c.currentTab.value == AlbumTab.video
            ? '还没有上传视频，点击右上角上传'
            : c.currentTab.value == AlbumTab.image
                ? '还没有上传图片，点击右上角上传'
                : '还没有素材，上传第一张吧';
    return Center(
      child: Column(
        children: [
          Icon(
            c.currentTab.value == AlbumTab.star
                ? Icons.star_border
                : Icons.image_outlined,
            color: AppTheme.textSecondary,
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(tip,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final MediaGroup g;
  _Group({required this.g});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<AlbumController>();
    // 收藏 tab 下按时间排序；其他保持后端顺序
    final items = c.currentTab.value == AlbumTab.star
        ? (List<MediaItem>.from(g.items)
          ..sort((a, b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0))))
        : g.items;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(g.scheduleTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: items.map((m) => _MediaCard(m: m)).toList(),
          ),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final MediaItem m;
  _MediaCard({required this.m});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<AlbumController>();
    return GestureDetector(
      onLongPress: () => c.toggleStar(m),
      onTap: () => Get.dialog(_PreviewDialog(m: m, c: c)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: m.mediaType == 'video'
                        ? CachedNetworkImage(
                            imageUrl: m.fullThumbUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (c, e) => Container(
                              color: Colors.black,
                              child: const Center(
                                child: Icon(Icons.play_circle_outline,
                                    color: Colors.white, size: 40),
                              ),
                            ),
                            errorWidget: (c, e, s) => Container(
                              color: Colors.black,
                              child: const Center(
                                child: Icon(Icons.play_circle_outline,
                                    color: Colors.white, size: 40),
                              ),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: m.fullUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorWidget: (c, e, s) => Container(
                              color: AppTheme.bgColor,
                              child: const Icon(Icons.broken_image,
                                  color: AppTheme.textSecondary),
                            ),
                          ),
                  ),
                  // 视频再叠一个半透明播放图标（缩略图有的话就不那么突兀）
                  if (m.mediaType == 'video')
                    const Center(
                      child: Icon(Icons.play_circle_outline,
                          color: Colors.white70, size: 40),
                    ),
                  if (m.isStar == 1)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.star, color: Colors.amber, size: 18),
                    ),
                  if (m.mediaType == 'video')
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDur(m.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
              child: Text(
                m.remark.isNotEmpty ? m.remark : (m.schedule?.title ?? ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
              child: Row(
                children: [
                  Icon(Icons.person, size: 10, color: AppTheme.textSecondary),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      m.uploader?.nickname.isNotEmpty == true
                          ? m.uploader!.nickname
                          : '未知',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  Text(
                    m.dateText,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDur(int s) {
    final m = s ~/ 60;
    final ss = s % 60;
    return '${m.toString().padLeft(1, '0')}:${ss.toString().padLeft(2, '0')}';
  }
}

class _PreviewDialog extends StatefulWidget {
  final MediaItem m;
  final AlbumController c;
  const _PreviewDialog({required this.m, required this.c});
  @override
  State<_PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<_PreviewDialog> {
  VideoPlayerController? _vp;
  bool _vpReady = false;
  bool _vpError = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    if (widget.m.mediaType == 'video') {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      _vp = VideoPlayerController.networkUrl(Uri.parse(widget.m.fullUrl));
      await _vp!.initialize();
      await _vp!.setLooping(false);
      if (!mounted) return;
      setState(() => _vpReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _vpError = true);
    }
  }

  void _togglePlay() {
    if (_vp == null || !_vpReady) return;
    setState(() {
      if (_playing) {
        _vp!.pause();
        _playing = false;
      } else {
        _vp!.play();
        _playing = true;
      }
    });
  }

  @override
  void dispose() {
    _vp?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final c = widget.c;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: m.mediaType == 'video'
                ? _buildVideo(m)
                : CachedNetworkImage(
                    imageUrl: m.fullUrl,
                    fit: BoxFit.contain,
                    errorWidget: (c, e, s) => Container(
                      color: AppTheme.bgColor,
                      height: 400,
                      child: const Icon(Icons.broken_image,
                          color: AppTheme.textSecondary, size: 60),
                    ),
                  ),
          ),
          // 底部信息条
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Row(
                children: [
                  if (m.uploader?.avatar != null &&
                      m.uploader!.avatar.isNotEmpty)
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: m.uploader!.avatar.startsWith('http')
                            ? m.uploader!.avatar
                            : '${Env.apiBaseUrl}${m.uploader!.avatar}',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorWidget: (c, e, s) => Container(
                          color: Colors.white24,
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    )
                  else
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.uploader?.nickname.isNotEmpty == true
                              ? m.uploader!.nickname
                              : '未知',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (m.createdAt != null)
                          Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(m.createdAt!),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 右上角操作按钮
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    m.isStar == 1 ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () async {
                    await c.toggleStar(m);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () async {
                    await c.deleteMedia(m.id);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideo(MediaItem m) {
    if (_vpError) {
      return Container(
        color: Colors.black,
        height: 400,
        child: const Center(
          child: Text('视频加载失败',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ),
      );
    }
    if (!_vpReady || _vp == null) {
      return Container(
        color: Colors.black,
        height: 400,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _vp!.value.aspectRatio == 0
                ? 16 / 9
                : _vp!.value.aspectRatio,
            child: VideoPlayer(_vp!),
          ),
          if (!_playing)
            const Icon(Icons.play_circle_outline,
                color: Colors.white, size: 72),
          // 视频进度
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              _vp!,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white38,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
