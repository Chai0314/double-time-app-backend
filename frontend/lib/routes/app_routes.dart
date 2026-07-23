import 'package:get/get.dart';

import '../modules/auth/auth_controller.dart';
import '../modules/auth/login_page.dart';
import '../modules/auth/register_page.dart';
import '../modules/couple/bind_page.dart';
import '../modules/legal/privacy_policy_page.dart';
import '../modules/legal/user_agreement_page.dart';
import '../modules/profile/edit_profile_page.dart';
import 'main_shell.dart';

class AppRoutes {
  /// 不需要登录即可访问的公开路由
  static const _publicRoutes = {
    '/login',
    '/register',
    '/user-agreement',
    '/privacy-policy',
  };

  static final pages = [
    GetPage(name: '/login', page: () => const LoginPage()),
    GetPage(name: '/register', page: () => const RegisterPage()),
    GetPage(name: '/bind', page: () => const BindPage()),
    GetPage(name: '/main', page: () => const MainShell()),
    GetPage(name: '/edit-profile', page: () => const EditProfilePage()),
    GetPage(name: '/user-agreement', page: () => const UserAgreementPage()),
    GetPage(name: '/privacy-policy', page: () => const PrivacyPolicyPage()),
  ];

  /// 根据 Auth 状态决定初始路由
  static String initialRoute() {
    final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    if (auth == null) return '/login';
    if (!auth.isLogin.value) return '/login';
    if (!auth.hasCouple) return '/bind';
    return '/main';
  }

  /// 路由守卫：未登录访问受保护页面时自动跳到登录页。
  static void guard(Routing? routing) {
    if (routing == null) return;
    final to = routing.current;
    if (to.isEmpty) return;
    // 公开页面（登录/注册/协议/政策）放行
    if (_publicRoutes.contains(to)) return;
    // 已登录：放行；未登录：跳到登录页
    final auth =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    if (auth != null && auth.isLogin.value) return;
    Future.microtask(() {
      if (Get.currentRoute != '/login') {
        Get.offAllNamed('/login');
      }
    });
  }
}
