import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_error.dart';
import '../../core/config/env.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../auth/auth_controller.dart';

/// 编辑资料页
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final c = Get.find<AuthController>();
  final repo = AuthRepository();
  final picker = ImagePicker();

  final formKey = GlobalKey<FormState>();
  late final TextEditingController nicknameCtrl;
  late final TextEditingController bioCtrl;
  late final TextEditingController phoneCtrl;

  int gender = 0; // 0未知 1男 2女
  DateTime? anniversary;
  TimeOfDay? workStart;
  TimeOfDay? workEnd;
  String avatar = '';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final u = c.user;
    nicknameCtrl = TextEditingController(text: u?.nickname ?? '');
    bioCtrl = TextEditingController(text: u?.bio ?? '');
    phoneCtrl = TextEditingController(text: u?.phone ?? '');
    gender = u?.gender ?? 0;
    avatar = u?.avatar ?? '';
    if (u?.anniversary != null && u!.anniversary!.isNotEmpty) {
      anniversary = DateTime.tryParse(u.anniversary!);
    }
    workStart = _parseHm(u?.workStart);
    workEnd = _parseHm(u?.workEnd);
  }

  @override
  void dispose() {
    nicknameCtrl.dispose();
    bioCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  TimeOfDay? _parseHm(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '未设置';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '未设置';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  /// 选头像
  Future<void> _pickAvatar() async {
    try {
      final XFile? f = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (f == null) return;
      setState(() => saving = true);
      final r = await repo.uploadAvatar(f);
      // 立即更新 controller 里的 currentUser
      c.currentUser.value = r.user;
      setState(() {
        avatar = r.avatar;
        saving = false;
      });
      Get.snackbar('已更新', '头像已更新');
    } catch (e) {
      setState(() => saving = false);
      showError(e, title: '上传失败');
    }
  }

  /// 保存资料
  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final patch = <String, dynamic>{
        'nickname': nicknameCtrl.text.trim(),
        'gender': gender,
        'bio': bioCtrl.text.trim(),
        'phone': phoneCtrl.text.trim().isEmpty ? '' : phoneCtrl.text.trim(),
        'anniversary': anniversary == null
            ? null
            : '${anniversary!.year.toString().padLeft(4, '0')}-'
                '${anniversary!.month.toString().padLeft(2, '0')}-'
                '${anniversary!.day.toString().padLeft(2, '0')}',
        'workStart':
            workStart == null ? '' : _fmtTime(workStart),
        'workEnd': workEnd == null ? '' : _fmtTime(workEnd),
      };
      final updated = await repo.updateMe(patch);
      c.currentUser.value = updated;
      Get.back();
      Get.snackbar('已保存', '资料已更新');
    } catch (e) {
      showError(e, title: '保存失败');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('编辑资料'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: saving ? null : _save,
            child: const Text('保存', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _avatarCard(),
              const SizedBox(height: 16),
              _section(
                '基础信息',
                [
                  _field(
                    label: '昵称',
                    child: TextFormField(
                      controller: nicknameCtrl,
                      maxLength: 24,
                      decoration: const InputDecoration(
                        hintText: '请输入昵称',
                        counterText: '',
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return '请输入昵称';
                        if (s.length > 24) return '昵称最多 24 个字符';
                        return null;
                      },
                    ),
                  ),
                  _field(
                    label: '性别',
                    child: Row(
                      children: [
                        _genderChip(0, '保密'),
                        const SizedBox(width: 8),
                        _genderChip(1, '男'),
                        const SizedBox(width: 8),
                        _genderChip(2, '女'),
                      ],
                    ),
                  ),
                  _field(
                    label: '手机号',
                    child: TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: const InputDecoration(hintText: '选填，11 位手机号'),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return null;
                        if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(s)) {
                          return '手机号格式不正确';
                        }
                        return null;
                      },
                    ),
                  ),
                  _field(
                    label: '个性签名',
                    child: TextFormField(
                      controller: bioCtrl,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        hintText: '一句话介绍一下自己吧',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _section(
                '关系',
                [
                  _field(
                    label: '纪念日',
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: anniversary ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2035),
                        );
                        if (d != null) setState(() => anniversary = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _fmtDate(anniversary),
                                style: TextStyle(
                                  color: anniversary == null
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _section(
                '作息',
                [
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          label: '开始',
                          child: InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime:
                                    workStart ?? const TimeOfDay(hour: 9, minute: 0),
                              );
                              if (t != null) setState(() => workStart = t);
                            },
                            child: _timeBox(_fmtTime(workStart)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          label: '结束',
                          child: InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime:
                                    workEnd ?? const TimeOfDay(hour: 18, minute: 0),
                              );
                              if (t != null) setState(() => workEnd = t);
                            },
                            child: _timeBox(_fmtTime(workEnd)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _showChangePwdDialog(),
                icon: const Icon(Icons.lock_outline, size: 16),
                label: const Text('修改密码'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarCard() {
    final hasAvatar = avatar.isNotEmpty;
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: saving ? null : _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasAvatar
                      ? CachedNetworkImage(
                          imageUrl: avatar.startsWith('http')
                              ? avatar
                              : '${Env.apiBaseUrl}$avatar',
                          fit: BoxFit.cover,
                          errorWidget: (c, e, s) => const Icon(
                            Icons.person,
                            color: AppTheme.primary,
                            size: 44,
                          ),
                        )
                      : const Icon(Icons.person,
                          color: AppTheme.primary, size: 44),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('点击更换头像',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _genderChip(int v, String label) {
    final active = gender == v;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => setState(() => gender = v),
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: active ? Colors.white : AppTheme.textPrimary,
        fontSize: 13,
      ),
      backgroundColor: const Color(0xFFF7F7F7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _field({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _timeBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14)),
          const Icon(Icons.access_time, color: AppTheme.textSecondary, size: 16),
        ],
      ),
    );
  }

  Future<void> _showChangePwdDialog() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool busy = false;

    await Get.dialog(
      StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          title: const Text('修改密码'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: '原密码'),
                  validator: (v) =>
                      (v ?? '').isEmpty ? '请输入原密码' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: '新密码（至少 6 位）'),
                  validator: (v) {
                    final s = v ?? '';
                    if (s.isEmpty) return '请输入新密码';
                    if (s.length < 6) return '至少 6 位';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: '确认新密码'),
                  validator: (v) =>
                      v != newCtrl.text ? '两次密码不一致' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: busy ? null : () => Get.back(),
                child: const Text('取消')),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setSt(() => busy = true);
                      try {
                        await repo.changePassword(
                          oldPassword: oldCtrl.text,
                          newPassword: newCtrl.text,
                        );
                        Get.back();
                        Get.snackbar('已更新', '密码已修改');
                      } catch (e) {
                        showError(e, title: '修改失败');
                      } finally {
                        setSt(() => busy = false);
                      }
                    },
              child: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('确认'),
            ),
          ],
        );
      }),
    );
  }
}
