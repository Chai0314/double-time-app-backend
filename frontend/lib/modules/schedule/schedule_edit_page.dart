import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_error.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/schedule_model.dart';
import 'schedule_controller.dart';

class ScheduleEditPage extends StatefulWidget {
  final DateTime selected;
  final Schedule? existing; // 非空 = 编辑模式
  const ScheduleEditPage({
    super.key,
    required this.selected,
    this.existing,
  });

  @override
  State<ScheduleEditPage> createState() => _ScheduleEditPageState();
}

class _ScheduleEditPageState extends State<ScheduleEditPage> {
  final _titleCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController(text: '0');

  String _category = 'date';
  DateTime _start = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _end = DateTime.now();
  TimeOfDay? _endTime;
  int _remind = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _initFromExisting(widget.existing!);
    } else {
      _start = widget.selected;
      _end = widget.selected;
      _startTime = const TimeOfDay(hour: 12, minute: 0);
    }
  }

  void _initFromExisting(Schedule s) {
    _titleCtrl.text = s.title;
    _addressCtrl.text = s.address;
    _remarkCtrl.text = s.remark ?? '';
    _budgetCtrl.text = s.budget.toStringAsFixed(0);
    _category = s.category;
    final st = s.startTime.toLocal();
    _start = DateTime(st.year, st.month, st.day);
    _startTime = TimeOfDay(hour: st.hour, minute: st.minute);
    if (s.endTime != null) {
      final et = s.endTime!.toLocal();
      _end = DateTime(et.year, et.month, et.day);
      _endTime = TimeOfDay(hour: et.hour, minute: et.minute);
    } else {
      _end = _start;
      _endTime = null;
    }
    _remind = s.remindOffset;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    _remarkCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      Get.snackbar('提示', '请填写行程标题');
      return;
    }
    setState(() => _saving = true);
    try {
      final st = DateTime(
        _start.year, _start.month, _start.day,
        _startTime.hour, _startTime.minute,
      );
      DateTime? et;
      if (_endTime != null) {
        et = DateTime(
          _end.year, _end.month, _end.day,
          _endTime!.hour, _endTime!.minute,
        );
      }
      final data = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'category': _category,
        'address': _addressCtrl.text.trim(),
        'startTime': st.toIso8601String(),
        'endTime': et?.toIso8601String(),
        'remindOffset': _remind,
        'budget': double.tryParse(_budgetCtrl.text) ?? 0,
        'remark': _remarkCtrl.text.trim(),
        'repeatType': 'none',
      };
      final ctl = Get.find<ScheduleController>();
      if (widget.existing != null) {
        await ctl.updateSchedule(widget.existing!.id, data);
      } else {
        await ctl.createSchedule(data);
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
        title: Text(widget.existing != null ? '编辑行程' : '新建行程'),
        backgroundColor: AppTheme.bgColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _field('行程标题', TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: '想去做什么？'))),
          const SizedBox(height: 16),
          const Text('分类', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              const _CatItem(value: 'date', label: '约会', icon: Icons.local_cafe),
              const _CatItem(value: 'travel', label: '旅游', icon: Icons.flight_takeoff),
              const _CatItem(value: 'home', label: '居家', icon: Icons.home),
              const _CatItem(value: 'festival', label: '节日', icon: Icons.cake),
              const _CatItem(value: 'errand', label: '事务', icon: Icons.assignment),
              const _CatItem(value: 'other', label: '其他', icon: Icons.more_horiz),
            ].map((w) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _category = w.value),
                  child: w.copyWith(selected: _category == w.value),
                )).toList(),
          ),
          const SizedBox(height: 16),
          _DateTimeRow(
            label: '开始',
            date: _start,
            time: _startTime,
            onDate: (d) => setState(() => _start = d),
            onTime: (t) => setState(() => _startTime = t),
          ),
          const SizedBox(height: 12),
          _DateTimeRow(
            label: '结束',
            date: _end,
            time: _endTime,
            onDate: (d) => setState(() => _end = d),
            onTime: (t) => setState(() => _endTime = t),
            clearable: true,
            onClear: () => setState(() => _endTime = null),
          ),
          const SizedBox(height: 16),
          _field('地点',
              TextField(controller: _addressCtrl, decoration: const InputDecoration(hintText: '在哪里？'))),
          const SizedBox(height: 16),
          _field('预算',
              TextField(controller: _budgetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '¥ '))),
          const SizedBox(height: 16),
          _field('备注', TextField(controller: _remarkCtrl, maxLines: 3, decoration: const InputDecoration(hintText: '行程细节、注意事项...'))),
          const SizedBox(height: 16),
          const Text('提醒', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _remindChip(0, '不提醒'),
              _remindChip(10, '提前10分钟'),
              _remindChip(30, '提前30分钟'),
              _customRemindChip(),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('保存行程'),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _remindChip(int m, String label) {
    final active = _remind == m;
    return ChoiceChip(
      selected: active,
      selectedColor: AppTheme.primary,
      label: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : AppTheme.textPrimary,
          fontSize: 12,
        ),
      ),
      onSelected: (_) => setState(() => _remind = m),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _customRemindChip() {
    final isCustom = _remind != 0 && _remind != 10 && _remind != 30;
    return ActionChip(
      label: Text(
        isCustom ? _remindLabel(_remind) : '自定义',
        style: TextStyle(
          color: isCustom ? Colors.white : AppTheme.textPrimary,
          fontSize: 12,
        ),
      ),
      backgroundColor: isCustom ? AppTheme.primary : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: _pickCustomRemind,
    );
  }

  Future<void> _pickCustomRemind() async {
    int initialUnit;
    int initialNum;
    if (_remind == 0 || _remind == 10 || _remind == 30) {
      initialUnit = 0;
      initialNum = 15;
    } else if (_remind % 1440 == 0) {
      initialUnit = 2;
      initialNum = _remind ~/ 1440;
    } else if (_remind % 60 == 0) {
      initialUnit = 1;
      initialNum = _remind ~/ 60;
    } else {
      initialUnit = 0;
      initialNum = _remind;
    }

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int unit = initialUnit;
        final ctrl = TextEditingController(text: initialNum.toString());
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('自定义提醒'),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('提前'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: unit,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('分钟')),
                    DropdownMenuItem(value: 1, child: Text('小时')),
                    DropdownMenuItem(value: 2, child: Text('天')),
                  ],
                  onChanged: (v) => setLocal(() => unit = v ?? 0),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final n = int.tryParse(ctrl.text.trim());
                  if (n == null || n <= 0) {
                    Get.snackbar('提示', '请输入正整数');
                    return;
                  }
                  final m = unit == 0 ? n : unit == 1 ? n * 60 : n * 1440;
                  Navigator.pop(ctx, m);
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      },
    );
    if (result != null) setState(() => _remind = result);
  }

  String _remindLabel(int m) {
    if (m < 60) return '提前${m}分钟';
    if (m < 1440) return '提前${m ~/ 60}小时';
    return '提前${m ~/ 1440}天';
  }
}

class _CatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  const _CatItem({
    required this.value,
    required this.label,
    required this.icon,
    this.selected = false,
  });

  _CatItem copyWith({bool? selected}) => _CatItem(
        value: value,
        label: label,
        icon: icon,
        selected: selected ?? this.selected,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppTheme.primary : AppTheme.primary.withOpacity(0.3),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: selected ? Colors.white : AppTheme.primary, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : AppTheme.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final TimeOfDay? time;
  final void Function(DateTime) onDate;
  final void Function(TimeOfDay) onTime;
  final bool clearable;
  final VoidCallback? onClear;
  const _DateTimeRow({
    required this.label,
    required this.date,
    required this.time,
    required this.onDate,
    required this.onTime,
    this.clearable = false,
    this.onClear,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (d != null) onDate(d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(DateFormat('yyyy-MM-dd').format(date)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: time ?? const TimeOfDay(hour: 12, minute: 0),
            );
            if (t != null) onTime(t);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(time == null ? '--:--' : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'),
          ),
        ),
        if (clearable)
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
            onPressed: onClear,
          ),
      ],
    );
  }
}
