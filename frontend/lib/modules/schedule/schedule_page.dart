import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/schedule_model.dart';
import 'schedule_controller.dart';
import 'schedule_edit_page.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ScheduleController());
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('我们的行程'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.primary),
            onPressed: () => _goCreate(c),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _ViewSwitcher(c: c),
          _Calendar(c: c),
          const SizedBox(height: 8),
          _DayList(c: c),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-schedule',
        backgroundColor: AppTheme.primary,
        onPressed: () => _goCreate(c),
        icon: const Icon(Icons.add),
        label: const Text('新建行程'),
      ),
    );
  }

  void _goCreate(ScheduleController c) async {
    final ok = await Get.to(() => ScheduleEditPage(
          selected: c.selectedDay.value,
        ));
    if (ok == true) {
      c.loadMonth(c.focusedDay.value.year, c.focusedDay.value.month);
      c.loadDay(c.selectedDay.value);
    }
  }
}

Future<void> _goScheduleEdit(Schedule s) async {
  final ok = await Get.to(() => ScheduleEditPage(
        selected: s.startTime.toLocal(),
        existing: s,
      ));
  if (ok == true) {
    final c = Get.find<ScheduleController>();
    c.loadMonth(c.focusedDay.value.year, c.focusedDay.value.month);
    c.loadDay(c.selectedDay.value);
  }
}

class _ViewSwitcher extends StatelessWidget {
  final ScheduleController c;
  const _ViewSwitcher({required this.c});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Obx(() => Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _btn('月', CalendarFormat.month),
                _btn('周', CalendarFormat.twoWeeks),
                _btn('日', CalendarFormat.week),
              ],
            ),
          )),
    );
  }

  Widget _btn(String label, CalendarFormat f) {
    final active = c.format.value == f;
    return Expanded(
      child: GestureDetector(
        onTap: () => c.format.value = f,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '$label视图',
              style: TextStyle(
                color: active ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  final ScheduleController c;
  const _Calendar({required this.c});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(12),
        child: Obx(() => TableCalendar(
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2035, 12, 31),
              focusedDay: c.focusedDay.value,
              selectedDayPredicate: (d) =>
                  isSameDay(d, c.selectedDay.value),
              calendarFormat: c.format.value,
              onFormatChanged: (f) => c.format.value = f,
              onPageChanged: c.onPageChanged,
              onDaySelected: c.onDaySelected,
              locale: 'zh_CN',
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(color: AppTheme.danger),
                outsideDaysVisible: false,
              ),
              eventLoader: (d) {
                final k = DateTime(d.year, d.month, d.day);
                return c.eventMarker[k] != null ? [k] : [];
              },
            )),
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  final ScheduleController c;
  const _DayList({required this.c});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() {
        final list = c.daySchedules;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '${DateFormat('MM月dd日 EEEE', 'zh_CN').format(c.selectedDay.value)} (${list.length})',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('当天没有行程', style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ),
            ...list.map((s) => _ScheduleCard(s: s)),
          ],
        );
      }),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Schedule s;
  const _ScheduleCard({required this.s});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _goScheduleEdit(s),
      behavior: HitTestBehavior.opaque,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(
            color: s.status == 2 ? AppTheme.success : AppTheme.primary,
            width: 4,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon(s.category),
                color: s.status == 2 ? AppTheme.success : AppTheme.primary),
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
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusBg(s.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_statusText(s.status),
                          style: TextStyle(
                            color: _statusFg(s.status),
                            fontSize: 10,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('HH:mm').format(s.startTime.toLocal())}'
                  '${s.endTime != null ? ' - ${DateFormat('HH:mm').format(s.endTime!.toLocal())}' : ''}'
                  '${s.address.isNotEmpty ? ' · ${s.address}' : ''}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                if (s.members.isNotEmpty || s.budget > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (s.members.isNotEmpty)
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.people,
                                  size: 13, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  s.members
                                      .map((m) => m.nickname.isNotEmpty
                                          ? m.nickname
                                          : '?')
                                      .join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Spacer(),
                      if (s.budget > 0)
                        Text('¥${s.budget.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            )),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppTheme.textSecondary, size: 20),
            onPressed: () => _goScheduleEdit(s),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary),
            onPressed: () async {
              final ok = await Get.dialog<bool>(AlertDialog(
                title: const Text('确认删除'),
                content: Text('删除行程「${s.title}」？'),
                actions: [
                  TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('取消')),
                  TextButton(
                      onPressed: () => Get.back(result: true),
                      child: const Text('删除',
                          style: TextStyle(color: AppTheme.danger))),
                ],
              ));
              if (ok == true) {
                await Get.find<ScheduleController>().deleteSchedule(s.id);
              }
            },
          ),
        ],
      ),
      ),
    );
  }

  IconData _icon(String c) {
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

  String _statusText(int s) =>
      const ['待开始', '进行中', '已完成', '已取消'][s];
  Color _statusBg(int s) => const [
        Color(0xFFE3F2FD),
        Color(0xFFE8F5E9),
        Color(0xFFE0E0E0),
        Color(0xFFFFEBEE)
      ][s];
  Color _statusFg(int s) => const [
        Color(0xFF1976D2),
        AppTheme.success,
        AppTheme.textSecondary,
        AppTheme.danger
      ][s];
}
