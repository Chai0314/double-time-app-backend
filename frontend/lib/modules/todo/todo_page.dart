import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/todo_model.dart';
import 'todo_controller.dart';
import 'todo_edit_page.dart';

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(TodoController());
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('我们的待办'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.primary),
            onPressed: () => _goCreate(c),
          ),
        ],
      ),
      body: Obx(() {
        if (c.loading.value && c.todos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: c.refreshList,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              _Stats(c: c),
              _Filters(c: c),
              ...c.todos.map((t) => _TodoCard(t: t, c: c)),
              if (c.todos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text('暂无待办，点右下角新建吧',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-todo',
        backgroundColor: AppTheme.primary,
        onPressed: () => _goCreate(c),
        icon: const Icon(Icons.add),
        label: const Text('新建待办'),
      ),
    );
  }

  Future<void> _goCreate(TodoController c) async {
    final ok = await Get.to(() => const TodoEditPage());
    if (ok == true) await c.refreshList();
  }
}

Future<void> _goTodoEdit(Todo t) async {
  final ok = await Get.to(() => TodoEditPage(existing: t));
  if (ok == true) await Get.find<TodoController>().refreshList();
}

class _Stats extends StatelessWidget {
  final TodoController c;
  const _Stats({required this.c});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(child: _box('我负责', c.mineTotal.value, const Color(0xFFFFB5C2))),
          const SizedBox(width: 8),
          Expanded(child: _box('TA负责', c.partnerTotal.value, const Color(0xFFFFDAB9))),
          const SizedBox(width: 8),
          Expanded(child: _box('共同', c.commonTotal.value, const Color(0xFFB2DFDB))),
        ],
      ),
    );
  }

  Widget _box(String label, int n, Color c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: c.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(color: c.withOpacity(0.9), fontSize: 11)),
            const SizedBox(height: 4),
            Text('$n',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

class _Filters extends StatelessWidget {
  final TodoController c;
  const _Filters({required this.c});
  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', '全部'),
      ('mine', '我的'),
      ('partner', 'TA的'),
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((f) {
          final active = c.filter.value == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => c.setFilter(f.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    color: active ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  final Todo t;
  final TodoController c;
  const _TodoCard({required this.t, required this.c});
  @override
  Widget build(BuildContext context) {
    Color borderColor;
    if (t.isOverdue) {
      borderColor = AppTheme.danger;
    } else if (t.level == 1) {
      borderColor = AppTheme.warning;
    } else if (t.repeatType != 'none') {
      borderColor = const Color(0xFF64B5F6);
    } else {
      borderColor = const Color(0xFFE0E0E0);
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => c.toggleComplete(t),
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: t.status == 2 ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: t.status == 2
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: t.status == 2
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
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
                      child: Text(
                        t.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          decoration: t.status == 2
                              ? TextDecoration.lineThrough
                              : null,
                          color: t.status == 2
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    _badge(t),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (t.deadline != null) ...[
                      const Icon(Icons.alarm,
                          size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MM-dd HH:mm').format(t.deadline!.toLocal()),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (t.executor != null)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 9,
                            backgroundColor: AppTheme.primaryLight,
                            child: Text(
                              t.executor!.nickname.isNotEmpty
                                  ? t.executor!.nickname.characters.first
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            t.executor!.nickname,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Icon(Icons.people,
                              size: 12, color: AppTheme.textSecondary),
                          SizedBox(width: 4),
                          Text('共同',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              )),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppTheme.textSecondary, size: 20),
            onPressed: () => _goTodoEdit(t),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.textSecondary, size: 20),
            onPressed: () async {
              final ok = await Get.dialog<bool>(AlertDialog(
                title: const Text('删除待办'),
                content: Text('确认删除「${t.title}」？'),
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
              if (ok == true) await c.deleteTodo(t.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _badge(Todo t) {
    if (t.isOverdue) {
      return _badgeText('逾期', AppTheme.danger, const Color(0xFFFFEBEE));
    }
    if (t.level == 1) {
      return _badgeText('高优先级', AppTheme.warning, const Color(0xFFFFF3E0));
    }
    if (t.repeatType != 'none') {
      final txt = {'daily': '每日', 'weekly': '每周', 'monthly': '每月'}[t.repeatType] ?? '重复';
      return _badgeText('🔄 $txt', const Color(0xFF1976D2), const Color(0xFFE3F2FD));
    }
    return _badgeText('普通', AppTheme.textSecondary, const Color(0xFFF5F5F5));
  }

  Widget _badgeText(String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: TextStyle(color: fg, fontSize: 10)),
      );
}
