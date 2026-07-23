import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/schedule_model.dart';
import '../notifications/notifications_page.dart';
import '../schedule/schedule_page.dart';
import '../todo/todo_page.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(HomeController());
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: c.refreshAll,
        child: Obx(() {
          if (c.loading.value && c.overview.value == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final ov = c.overview.value;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _Header(),
              if (ov != null) _OverviewCards(ov: ov),
              const SizedBox(height: 16),
              _SectionTitle(
                title: '今日行程',
                action: '查看全部',
                onTap: () => Get.to(() => const SchedulePage()),
              ),
              ...c.todaySchedules.map((s) => _ScheduleCard(s: s)),
              if (c.todaySchedules.isEmpty)
                const _Empty(text: '今日还没有行程，去新建一个吧'),
              const SizedBox(height: 16),
              _TodoSection(),
              const SizedBox(height: 16),
              _StatsSection(),
            ],
          );
        }),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const _Avatars(),
              const SizedBox(width: 12),
              const Expanded(child: _CoupleTitle()),
              IconButton(
                onPressed: () => Get.to(() => const NotificationsPage()),
                icon: const Icon(Icons.notifications_active_outlined,
                    color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _Anniversary(),
        ],
      ),
    );
  }
}

class _Avatars extends StatelessWidget {
  const _Avatars();
  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return Obx(() {
      final ov = c.overview.value;
      final a = ov?.userA;
      final b = ov?.userB;
      return SizedBox(
        width: 76,
        height: 36,
        child: Stack(
          children: [
            _avatar(a?.avatar, a?.nickname, 0),
            _avatar(b?.avatar, b?.nickname, 22),
          ],
        ),
      );
    });
  }

  Widget _avatar(String? url, String? name, double left) {
    final hasAvatar = (url ?? '').isNotEmpty;
    final fullUrl = hasAvatar && !url!.startsWith('http')
        ? '${Env.apiBaseUrl}$url'
        : url ?? '';
    return Positioned(
      left: left,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasAvatar
            ? CachedNetworkImage(
                imageUrl: fullUrl,
                fit: BoxFit.cover,
                errorWidget: (c, e, s) => Center(
                  child: Text(
                    (name ?? '?').isNotEmpty
                        ? (name ?? '?').characters.first
                        : '?',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  (name ?? '?').isNotEmpty
                      ? (name ?? '?').characters.first
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }
}

class _CoupleTitle extends StatelessWidget {
  const _CoupleTitle();
  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return Obx(() {
      final ov = c.overview.value;
      final a = ov?.userA?.nickname ?? 'TA';
      final b = ov?.userB?.nickname ?? '我';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$a & $b',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              )),
          const Text('已绑定 · 一起记录甜蜜时光',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      );
    });
  }
}

class _Anniversary extends StatelessWidget {
  const _Anniversary();
  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return Obx(() {
      final days = c.overview.value?.anniversaryDays;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryLight],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('纪念日倒计时',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 6),
                ],
              ),
            ),
            Text(
              days != null ? '$days' : '—',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('天',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      );
    });
  }
}

class _OverviewCards extends StatelessWidget {
  final dynamic ov; // Overview
  const _OverviewCards({required this.ov});
  @override
  Widget build(BuildContext context) {
    final done = ov.todayTodoAll > 0
        ? (ov.todayTodoDone * 100 / ov.todayTodoAll).round()
        : 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFDAB9), AppTheme.primaryLight],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('本月共同行程',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('${ov.monthSchedules} 次',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 28,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            value: done.toDouble(),
                            color: AppTheme.primary,
                            radius: 12,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: (100 - done).toDouble(),
                            color: const Color(0xFFF3F4F6),
                            radius: 12,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('今日完成率',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const _SectionTitle({required this.title, this.action, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              )),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onTap,
              child: Text(action!,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
            ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Schedule s;
  const _ScheduleCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: BorderSide(color: AppTheme.primary, width: 4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconFor(s.category),
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(s.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(s.categoryText,
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('HH:mm').format(s.startTime.toLocal())}'
                    '${s.address.isNotEmpty ? ' · ${s.address}' : ''}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
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

  IconData _iconFor(String c) {
    switch (c) {
      case 'travel':
        return Icons.flight_takeoff;
      case 'home':
        return Icons.home;
      case 'festival':
        return Icons.cake;
      case 'errand':
        return Icons.assignment;
      default:
        return Icons.local_cafe;
    }
  }
}

class _TodoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: '今日待办',
          action: '查看全部',
          onTap: () => Get.to(() => const TodoPage()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              if (c.todayTodos.isEmpty) {
                return const _Empty(text: '今日没有待办');
              }
              return Column(
                children: c.todayTodos
                    .take(5)
                    .map((t) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                t.status == 2
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: t.status == 2
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  t.title,
                                  style: TextStyle(
                                    decoration: t.status == 2
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: t.status == 2
                                        ? AppTheme.textSecondary
                                        : AppTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (t.isOverdue)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('逾期',
                                      style: TextStyle(
                                        color: AppTheme.danger,
                                        fontSize: 10,
                                      )),
                                ),
                            ],
                          ),
                        ))
                    .toList(),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Obx(() {
          final ov = c.overview.value;
          if (ov == null) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('双人完成率',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              ...ov.completion.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(e.user.nickname,
                                style: const TextStyle(fontSize: 13)),
                            const Spacer(),
                            Text('${e.rate}%',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: e.rate / 100,
                          minHeight: 6,
                          backgroundColor: AppTheme.bgColor,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  )),
            ],
          );
        }),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(text, style: const TextStyle(color: AppTheme.textSecondary)),
        ),
      );
}
