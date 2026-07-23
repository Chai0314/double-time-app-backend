import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_error.dart';
import '../../core/config/env.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../auth/auth_controller.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: FutureBuilder<CoupleInfo>(
        future: AuthRepository().coupleInfo(),
        builder: (context, snap) {
          final info = snap.data;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _Header(),
              if (info != null) _Stats(info: info),
              _Settings(),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(48)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 12),
          const Text('双人时光',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              )),
          const Text('两个人的甜蜜空间',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 24),
          Obx(() {
            final me = Get.find<AuthController>().user;
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  _Avatar(url: me?.avatar, nickname: me?.nickname ?? ''),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(me?.nickname ?? '',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const Text('设置我的作息',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            )),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.to(() => const EditProfilePage()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.bgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('编辑资料',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          )),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final CoupleInfo info;
  const _Stats({required this.info});
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              _cell('相识天数', '${info.dayCount}'),
              _cell('累计行程', '${info.scheduleCount}'),
              _cell('甜蜜素材', '${info.mediaCount}'),
              _cell('待办', '${info.todoCount}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String label, String value) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                )),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                )),
          ],
        ),
      );
}

class _Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            _item(Icons.edit_outlined, '编辑资料', () {
              Get.to(() => const EditProfilePage());
            }),
            _divider(),
            _item(Icons.favorite, '纪念日', () {
              Get.dialog(_AnniversaryEdit());
            }),
            _divider(),
            Obx(() {
              final hasCouple = Get.find<AuthController>().hasCouple;
              if (hasCouple) {
                return _item(Icons.link, '解绑伴侣', () async {
                  final ok = await Get.dialog<bool>(AlertDialog(
                    title: const Text('解绑确认'),
                    content: const Text('解绑后共享数据将隔离，确认解绑吗？'),
                    actions: [
                      TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('取消')),
                      TextButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text('解绑',
                              style: TextStyle(color: AppTheme.danger))),
                    ],
                  ));
                  if (ok == true) {
                    try {
                      await Get.find<AuthController>().unbind();
                      Get.snackbar('已解绑', '');
                    } catch (e) {
                      showError(e, title: '解绑失败');
                    }
                  }
                }, danger: true);
              } else {
                return _item(Icons.link, '绑定伴侣', () {
                  Get.toNamed('/bind');
                });
              }
            }),
            _divider(),
            _item(Icons.description_outlined, '用户协议', () {
              Get.toNamed('/user-agreement');
            }),
            _divider(),
            _item(Icons.shield_outlined, '隐私政策', () {
              Get.toNamed('/privacy-policy');
            }),
            _divider(),
            _item(Icons.logout, '退出登录', () async {
              await Get.find<AuthController>().logout();
              Get.offAllNamed('/login');
            }, danger: true),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: danger ? AppTheme.danger : AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    color: danger ? AppTheme.danger : AppTheme.textPrimary,
                    fontSize: 14,
                  )),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF0F0F0));
}

class _AnniversaryEdit extends StatefulWidget {
  @override
  State<_AnniversaryEdit> createState() => _AnniversaryEditState();
}

class _AnniversaryEditState extends State<_AnniversaryEdit> {
  DateTime? _date;
  @override
  void initState() {
    super.initState();
    final s = Get.find<AuthController>().user?.anniversary;
    if (s != null) _date = DateTime.tryParse(s);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('纪念日'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_date == null ? '未设置' : _date!.toString().split(' ').first),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2035),
              );
              if (d != null) setState(() => _date = d);
            },
            child: const Text('选择日期'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            if (_date != null) {
              try {
                await Get.find<AuthController>().updateProfile({
                  'anniversary':
                      '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
                });
                Get.back();
                Get.snackbar('已保存', '');
              } catch (e) {
                showError(e, title: '保存失败');
              }
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// 头像组件：优先展示网络头像，无则回退首字；点击弹出"修改头像"操作表
class _Avatar extends StatelessWidget {
  final String? url;
  final String nickname;
  const _Avatar({required this.url, required this.nickname});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = (url ?? '').isNotEmpty;
    // 有头像时构造完整 URL；无头像时给一个空串给 CachedNetworkImageProvider 兜底（实际不会被使用）
    final raw = url ?? '';
    final fullUrl = hasAvatar && !raw.startsWith('http')
        ? '${Env.apiBaseUrl}$raw'
        : raw;
    final avatar = CircleAvatar(
      radius: 28,
      backgroundColor: AppTheme.bgColor,
      foregroundColor: AppTheme.primary,
      backgroundImage: hasAvatar ? CachedNetworkImageProvider(fullUrl) : null,
      onBackgroundImageError: hasAvatar ? (_, __) {} : null,
      child: hasAvatar
          ? null
          : Text(
              nickname.isNotEmpty ? nickname.characters.first : '?',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
    );
    return GestureDetector(
      onTap: () => _showAvatarSheet(context, hasAvatar),
      child: avatar,
    );
  }

  void _showAvatarSheet(BuildContext context, bool hasAvatar) {
    final c = Get.find<AuthController>();
    final repo = AuthRepository();
    final picker = ImagePicker();
    bool busy = false;

    Get.bottomSheet(
      SafeArea(
        child: StatefulBuilder(builder: (ctx, setSt) {
          return Container(
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
                const Text('修改头像',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('选择一个清晰的正方形图片',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 16),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  )
                else
                  Column(
                    children: [
                      _item(
                        Icons.photo_library_outlined,
                        '从相册选择',
                        () async {
                          final XFile? f = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                            maxWidth: 1024,
                          );
                          if (f == null) return;
                          setSt(() => busy = true);
                          try {
                            final r = await repo.uploadAvatar(f);
                            c.currentUser.value = r.user;
                            Get.back();
                            Get.snackbar('已更新', '头像已更新');
                          } catch (e) {
                            showError(e, title: '上传失败');
                          } finally {
                            if (ctx.mounted) setSt(() => busy = false);
                          }
                        },
                      ),
                      if (hasAvatar)
                        _item(
                          Icons.delete_outline,
                          '移除当前头像',
                          () async {
                            setSt(() => busy = true);
                            try {
                              final updated = await repo.updateMe({'avatar': ''});
                              c.currentUser.value = updated;
                              Get.back();
                              Get.snackbar('已移除', '已恢复默认头像');
                            } catch (e) {
                              showError(e, title: '移除失败');
                            } finally {
                              if (ctx.mounted) setSt(() => busy = false);
                            }
                          },
                          color: AppTheme.danger,
                        ),
                      _item(
                        Icons.close,
                        '取消',
                        () => Get.back(),
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap,
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
