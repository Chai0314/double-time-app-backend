import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'modules/auth/auth_controller.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);

  // 注册全局控制器
  final auth = Get.put(AuthController(), permanent: true);

  // 等待 token 校验完成再决定初始路由，避免刷新时把已登录用户弹回登录页
  await auth.ready;

  runApp(const CoupleSpaceApp());
}

class CoupleSpaceApp extends StatelessWidget {
  const CoupleSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.initialRoute(),
      getPages: AppRoutes.pages,
      defaultTransition: Transition.cupertino,
      // 路由守卫：未登录用户访问受保护页面时自动跳到登录页
      routingCallback: (routing) {
        AppRoutes.guard(routing);
      },
    );
  }
}
