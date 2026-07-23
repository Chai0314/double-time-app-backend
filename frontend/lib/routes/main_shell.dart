import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_theme.dart';
import '../modules/album/album_page.dart';
import '../modules/home/home_page.dart';
import '../modules/profile/profile_page.dart';
import '../modules/schedule/schedule_page.dart';
import '../modules/todo/todo_page.dart';
import '../modules/auth/auth_controller.dart';

/// 主框架：5 个 Tab
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _pages = const [
    HomePage(),
    SchedulePage(),
    TodoPage(),
    AlbumPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // 未绑定伴侣：提示一次但不强制跳转，用户可继续浏览首页
    Future.microtask(() {
      final auth = Get.find<AuthController>();
      if (!auth.hasCouple) {
        Get.snackbar(
          '提示',
          '你还没有绑定伴侣，部分共享功能暂不可用',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _item(0, Icons.home_outlined, Icons.home, '首页'),
                _item(1, Icons.calendar_today_outlined, Icons.calendar_today,
                    '行程'),
                _item(2, Icons.checklist_outlined, Icons.checklist, 'ToDo'),
                _item(3, Icons.image_outlined, Icons.image, '相册'),
                _item(4, Icons.person_outline, Icons.person, '我的'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, IconData activeIcon, String label) {
    final active = _index == i;
    return InkWell(
      onTap: () => setState(() => _index = i),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? activeIcon : icon,
                color: active ? AppTheme.primary : AppTheme.textSecondary,
                size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: active ? AppTheme.primary : AppTheme.textSecondary,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}
