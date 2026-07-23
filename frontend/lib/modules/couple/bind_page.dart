import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/api/api_error.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/clipboard_io.dart'
    if (dart.library.html) '../../core/utils/clipboard_web.dart';
import '../auth/auth_controller.dart';

/// 情侣绑定页
class BindPage extends StatefulWidget {
  const BindPage({super.key});

  @override
  State<BindPage> createState() => _BindPageState();
}

class _BindPageState extends State<BindPage> {
  final _codeCtrl = TextEditingController();
  String? _myInvite;
  bool _generating = false;
  bool _binding = false;

  @override
  void initState() {
    super.initState();
    _genInvite();
  }

  Future<void> _genInvite() async {
    setState(() => _generating = true);
    try {
      final code = await Get.find<AuthController>().createInvite();
      setState(() => _myInvite = code);
    } catch (e) {
      showError(e, title: '生成邀请码失败');
    } finally {
      setState(() => _generating = false);
    }
  }

  Future<void> _doBind() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      Get.snackbar('提示', '请输入对方邀请码');
      return;
    }
    setState(() => _binding = true);
    try {
      await Get.find<AuthController>().bind(code);
      Get.offAllNamed('/main');
    } catch (e) {
      showError(e, title: '绑定失败');
    } finally {
      setState(() => _binding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('绑定伴侣'),
        backgroundColor: AppTheme.bgColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.favorite, color: AppTheme.primary, size: 56),
            const SizedBox(height: 16),
            const Text(
              '我们一起记录时光',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '将你的邀请码发给 TA，或输入 TA 的邀请码完成绑定',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text(
                    '我的邀请码',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  _generating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _myInvite ?? '------',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                          ),
                        ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () async {
                      if (_myInvite == null) return;
                      try {
                        await copyToClipboard(_myInvite!);
                        Get.snackbar('已复制', '邀请码已复制到剪贴板');
                      } catch (e) {
                        showError(e, title: '复制失败');
                      }
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('复制'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('或输入对方邀请码',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '邀请码',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _binding ? null : _doBind,
              child: _binding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('绑定'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Get.offAllNamed('/main');
              },
              child: const Text('暂不绑定，稍后再说',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
