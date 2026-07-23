import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/api/api_error.dart';
import '../../core/theme/app_theme.dart';
import 'auth_controller.dart';

/// 注册页：手机号 + 密码 + 二次确认密码 + 昵称（可选）
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  /// 中国大陆手机号正则
  static final RegExp _phoneReg = RegExp(r'^1[3-9]\d{9}$');

  final c = Get.find<AuthController>();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController pwdCtrl = TextEditingController();
  final TextEditingController pwd2Ctrl = TextEditingController();
  final TextEditingController nickCtrl = TextEditingController();

  bool _agreed = false;
  bool _obscurePwd = true;
  bool _obscurePwd2 = true;

  @override
  void dispose() {
    phoneCtrl.dispose();
    pwdCtrl.dispose();
    pwd2Ctrl.dispose();
    nickCtrl.dispose();
    super.dispose();
  }

  String? _validatePhone(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '请输入手机号';
    if (!_phoneReg.hasMatch(s)) return '手机号格式不正确';
    return null;
  }

  String? _validatePassword(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return '请输入密码';
    if (s.length < 6) return '密码至少 6 位';
    return null;
  }

  String? _validatePassword2(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return '请再次输入密码';
    if (s != pwdCtrl.text) return '两次输入的密码不一致';
    return null;
  }

  Future<void> _doRegister() async {
    final phoneErr = _validatePhone(phoneCtrl.text);
    if (phoneErr != null) {
      Get.snackbar('提示', phoneErr);
      return;
    }
    final pwdErr = _validatePassword(pwdCtrl.text);
    if (pwdErr != null) {
      Get.snackbar('提示', pwdErr);
      return;
    }
    final pwd2Err = _validatePassword2(pwd2Ctrl.text);
    if (pwd2Err != null) {
      Get.snackbar('提示', pwd2Err);
      return;
    }
    if (!_agreed) {
      Get.snackbar('提示', '请先同意用户协议和隐私政策');
      return;
    }
    try {
      final nick = nickCtrl.text.trim();
      await c.register(
        account: phoneCtrl.text.trim(),
        password: pwdCtrl.text,
        nickname: nick.isEmpty ? null : nick,
      );
      // 注册成功：跳到绑定页（注册用户一定未绑定）
      Get.offAllNamed('/bind');
    } catch (e) {
      showError(e, title: '注册失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor,
        elevation: 0,
        title: const Text('注册新账号'),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: Icon(Icons.person_add, color: AppTheme.primary, size: 56),
              ),
              const SizedBox(height: 12),
              const Text(
                '创建你的双人时光账号',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
              _phoneField(),
              const SizedBox(height: 12),
              _nickField(),
              const SizedBox(height: 12),
              _passwordField(
                controller: pwdCtrl,
                hint: '请输入密码（至少 6 位）',
                obscure: _obscurePwd,
                onToggle: () =>
                    setState(() => _obscurePwd = !_obscurePwd),
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _passwordField(
                controller: pwd2Ctrl,
                hint: '请再次输入密码',
                obscure: _obscurePwd2,
                onToggle: () =>
                    setState(() => _obscurePwd2 = !_obscurePwd2),
                onSubmitted: (_) => _doRegister(),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      activeColor: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: _AgreementText()),
                ],
              ),
              const SizedBox(height: 20),
              Obx(() => ElevatedButton(
                    onPressed: c.loading.value ? null : _doRegister,
                    child: c.loading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('注册'),
                  )),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '已有账号？',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () => Get.offAllNamed('/login'),
                    child: const Text('去登录'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phoneField() {
    return TextField(
      controller: phoneCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      decoration: InputDecoration(
        hintText: '请输入手机号',
        prefixIcon: const Icon(Icons.phone_iphone),
        suffixIcon: phoneCtrl.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.cancel, size: 18),
                onPressed: () {
                  phoneCtrl.clear();
                  setState(() {});
                },
              ),
      ),
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _nickField() {
    return TextField(
      controller: nickCtrl,
      maxLength: 24,
      decoration: const InputDecoration(
        hintText: '昵称（选填，不填则使用手机号）',
        prefixIcon: Icon(Icons.face_outlined),
        counterText: '',
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required TextInputAction textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            size: 20,
            color: AppTheme.textSecondary,
          ),
          onPressed: onToggle,
        ),
      ),
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
    );
  }
}

/// 协议/政策可点击文案
class _AgreementText extends StatelessWidget {
  const _AgreementText();

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(color: AppTheme.textSecondary, fontSize: 12);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: '我已阅读并同意'),
          TextSpan(
            text: '《用户协议》',
            style: const TextStyle(
              color: AppTheme.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Get.toNamed('/user-agreement'),
          ),
          const TextSpan(text: '和'),
          TextSpan(
            text: '《隐私政策》',
            style: const TextStyle(
              color: AppTheme.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Get.toNamed('/privacy-policy'),
          ),
        ],
      ),
    );
  }
}
