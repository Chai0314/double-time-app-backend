import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/api/api_error.dart';
import '../../core/theme/app_theme.dart';
import 'auth_controller.dart';

/// 登录页
/// 主流程：运营商本机一键登录（自动读取本机卡号）
/// 兜底：手动输入手机号 + 密码
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// 中国大陆手机号正则
  static final RegExp _phoneReg = RegExp(r'^1[3-9]\d{9}$');

  final c = Get.find<AuthController>();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController pwdCtrl = TextEditingController();

  /// 自动读取到的本机手机号（运营商鉴权后回填）
  final RxnString detectedPhone = RxnString();

  /// 是否处于手动输入模式
  final RxBool manualMode = false.obs;

  /// 是否正在自动读取本机号
  final RxBool detecting = true.obs;

  /// 读取本机号失败提示
  final RxnString detectError = RxnString();

  @override
  void initState() {
    super.initState();
    _autoDetectPhone();
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    pwdCtrl.dispose();
    super.dispose();
  }

  /// App 打开即自动读取本机卡号
  Future<void> _autoDetectPhone() async {
    detecting.value = true;
    detectError.value = null;
    try {
      final phone = await c.detectLocalPhoneNumber();
      if (phone != null && phone.isNotEmpty) {
        detectedPhone.value = phone;
        phoneCtrl.text = phone;
      } else {
        detectError.value = '未能识别本机号码，请手动输入';
        // 读取失败：直接进入手动模式
        manualMode.value = true;
      }
    } catch (e) {
      detectError.value = '读取本机号码失败：${errorText(e)}';
      manualMode.value = true;
    } finally {
      detecting.value = false;
    }
  }

  /// 校验手机号
  String? _validatePhone(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '请输入手机号';
    if (!_phoneReg.hasMatch(s)) return '手机号格式不正确';
    return null;
  }

  /// 校验密码
  String? _validatePassword(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return '请输入密码';
    if (s.length < 6) return '密码至少 6 位';
    return null;
  }

  /// 一键登录流程
  Future<void> _doOneClickLogin() async {
    final phone = (detectedPhone.value ?? phoneCtrl.text).trim();
    if (!_phoneReg.hasMatch(phone)) {
      Get.snackbar('提示', '未识别到有效本机号码，请切换到手动输入');
      return;
    }
    try {
      // carrierToken 由运营商 SDK 返回，这里用占位串
      // 真实场景下应从运营商 SDK 鉴权后获取
      await c.phoneOneClickLogin(
        phone: phone,
        carrierToken:
            'mock_carrier_token_${DateTime.now().millisecondsSinceEpoch}',
      );
      _afterLogin();
    } catch (e) {
      showError(e, title: '一键登录失败');
    }
  }

  /// 手动登录
  Future<void> _doLogin() async {
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
    try {
      await c.login(
        account: phoneCtrl.text.trim(),
        password: pwdCtrl.text,
      );
      _afterLogin();
    } catch (e) {
      showError(e, title: '登录失败');
    }
  }

  void _afterLogin() {
    if (c.hasCouple) {
      Get.offAllNamed('/main');
    } else {
      Get.offAllNamed('/bind');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Center(
                child: Icon(Icons.favorite, color: AppTheme.primary, size: 64),
              ),
              const SizedBox(height: 16),
              const Text(
                '双人时光',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '两个人的甜蜜空间',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 56),
              Obx(() => _buildOneClickArea()),
              Obx(() => manualMode.value
                  ? const SizedBox(height: 20)
                  : const SizedBox.shrink()),
              Obx(() => manualMode.value
                  ? _buildManualArea()
                  : const SizedBox.shrink()),
              const SizedBox(height: 12),
              Obx(() => _buildToggleButton()),
              const SizedBox(height: 8),
              const _AgreementFooter(),
            ],
          ),
        ),
      ),
    );
  }

  /// 切换按钮：一键登录 <-> 手动输入
  Widget _buildToggleButton() {
    final hasPhone =
        detectedPhone.value != null && detectedPhone.value!.isNotEmpty;
    if (manualMode.value) {
      return Center(
        child: TextButton(
          onPressed: hasPhone
              ? () => manualMode.value = false
              : () {
                  // 没识别到本机号时，先重新尝试
                  _autoDetectPhone();
                },
          child: Text(
            hasPhone ? '使用本机号码一键登录' : '重新识别本机号码',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }
    return Center(
      child: TextButton(
        onPressed: () {
          manualMode.value = true;
          if (hasPhone) {
            phoneCtrl.text = detectedPhone.value!;
          }
        },
        child: const Text(
          '手动输入手机号登录',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  /// 一键登录区域：自动读取的本机号码 + 一键登录按钮
  /// 仅在已识别到本机号时展示
  Widget _buildOneClickArea() {
    if (detecting.value) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              '正在识别本机号码…',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    final phone = detectedPhone.value;
    if (phone == null || phone.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                '本机号码',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _maskPhone(phone),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: AppTheme.primary,
                    onPressed: () {
                      manualMode.value = true;
                      phoneCtrl.text = phone;
                    },
                    tooltip: '使用其他号码',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Obx(() => ElevatedButton(
              onPressed: c.loading.value ? null : _doOneClickLogin,
              child: c.loading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('本机号码一键登录'),
            )),
      ],
    );
  }

  /// 手动输入区域：手机号 + 密码 + 登录
  Widget _buildManualArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
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
        ),
        const SizedBox(height: 12),
        TextField(
          controller: pwdCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: '请输入密码（至少 6 位）',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 20),
        Obx(() => ElevatedButton(
              onPressed: c.loading.value ? null : _doLogin,
              child: c.loading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('登录'),
            )),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '还没有账号？',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/register'),
              child: const Text('立即注册'),
            ),
          ],
        ),
      ],
    );
  }

  /// 中间四位星号
  String _maskPhone(String phone) {
    if (phone.length != 11) return phone;
    return '${phone.substring(0, 3)} **** ${phone.substring(7)}';
  }
}

/// 登录页底部的「用户协议」「隐私政策」可点击文案
class _AgreementFooter extends StatelessWidget {
  const _AgreementFooter();

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      color: AppTheme.textSecondary,
      fontSize: 12,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            const TextSpan(text: '登录即表示同意'),
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
        textAlign: TextAlign.center,
      ),
    );
  }
}
