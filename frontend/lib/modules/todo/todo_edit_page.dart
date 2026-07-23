import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_error.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/todo_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'todo_controller.dart';

class TodoEditPage extends StatefulWidget {
  final Todo? existing; // 非空 = 编辑模式
  const TodoEditPage({super.key, this.existing});

  @override
  State<TodoEditPage> createState() => _TodoEditPageState();
}

class _TodoEditPageState extends State<TodoEditPage> {
  final _titleCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  int _level = 2;
  DateTime? _deadline;
  int? _executorId; // null = 共同
  bool _saving = false;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final t = widget.existing!;
      _titleCtrl.text = t.title;
      _remarkCtrl.text = t.remark ?? '';
      _level = t.level;
      _deadline = t.deadline?.toLocal();
      _executorId = t.executor?.id;
    }
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final list = await AuthRepository().members();
      setState(() {
        _members = list.map((e) => {'id': e.id, 'nickname': e.nickname}).toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      Get.snackbar('提示', '请填写任务标题');
      return;
    }
    if (_deadline == null) {
      Get.snackbar('提示', '请选择截止时间');
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'level': _level,
        'executorId': _executorId,
        'deadline': _deadline!.toIso8601String(),
        'remark': _remarkCtrl.text.trim(),
        'category': 'daily',
        'repeatType': 'none',
      };
      final ctl = Get.find<TodoController>();
      if (widget.existing != null) {
        await ctl.updateTodo(widget.existing!.id, data);
      } else {
        await ctl.createTodo(data);
      }
      Get.back(result: true);
    } catch (e) {
      showError(e, title: '保存失败');
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text(widget.existing != null ? '编辑待办' : '新建待办'),
        backgroundColor: AppTheme.bgColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('任务标题', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(hintText: '简洁明确'),
          ),
          const SizedBox(height: 16),
          const Text('优先级', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              _levelBtn(1, '高', AppTheme.danger),
              const SizedBox(width: 8),
              _levelBtn(2, '中', AppTheme.warning),
              const SizedBox(width: 8),
              _levelBtn(3, '低', AppTheme.success),
            ],
          ),
          const SizedBox(height: 16),
          const Text('执行人', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              _execBtn(null, '共同'),
              ..._members.map((m) => _execBtn(m['id'] as int, m['nickname'] as String)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('截止时间', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _deadline ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (d == null) return;
              if (!mounted) return;
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_deadline ?? DateTime.now()),
              );
              if (t == null) return;
              setState(() => _deadline = DateTime(d.year, d.month, d.day, t.hour, t.minute));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _deadline == null
                    ? '选择截止时间'
                    : DateFormat('yyyy-MM-dd HH:mm').format(_deadline!),
                style: TextStyle(
                  color: _deadline == null
                      ? AppTheme.textSecondary
                      : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('备注', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _remarkCtrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: '补充任务细节、所需物料...'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('保存待办'),
          ),
        ],
      ),
    );
  }

  Widget _levelBtn(int lv, String label, Color c) {
    final active = _level == lv;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _level = lv),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? c : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _execBtn(int? id, String name) {
    final active = _executorId == id;
    return GestureDetector(
      onTap: () => setState(() => _executorId = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
