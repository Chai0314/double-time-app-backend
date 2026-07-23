/// Todo
import 'schedule_model.dart' show UserBrief;

class Todo {
  final int id;
  final String title;
  final String category;
  final int level; // 1高 2中 3低
  final String levelText;
  final UserBrief? executor;
  final ScheduleBrief? schedule;
  final DateTime? deadline;
  final int remindOffset;
  final String repeatType;
  final String? remark;
  final int status;
  final String statusText;
  final bool isOverdue;
  final DateTime? completedAt;
  final UserBrief? creator;
  final DateTime? createdAt;

  Todo({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.levelText,
    this.executor,
    this.schedule,
    this.deadline,
    required this.remindOffset,
    required this.repeatType,
    this.remark,
    required this.status,
    required this.statusText,
    required this.isOverdue,
    this.completedAt,
    this.creator,
    this.createdAt,
  });

  factory Todo.fromJson(Map<String, dynamic> j) => Todo(
        id: (j['id'] as num).toInt(),
        title: (j['title'] ?? '') as String,
        category: (j['category'] ?? 'daily') as String,
        level: (j['level'] ?? 1) as int,
        levelText: (j['levelText'] ?? '中') as String,
        executor: j['executor'] == null
            ? null
            : UserBrief.fromJson(j['executor'] as Map<String, dynamic>),
        schedule: j['schedule'] == null
            ? null
            : ScheduleBrief.fromJson(j['schedule'] as Map<String, dynamic>),
        deadline: j['deadline'] == null ? null : DateTime.tryParse(j['deadline']),
        remindOffset: (j['remindOffset'] ?? 0) as int,
        repeatType: (j['repeatType'] ?? 'none') as String,
        remark: j['remark'] as String?,
        status: (j['status'] ?? 0) as int,
        statusText: (j['statusText'] ?? '待处理') as String,
        isOverdue: (j['isOverdue'] ?? false) as bool,
        completedAt: j['completedAt'] == null
            ? null
            : DateTime.tryParse(j['completedAt']),
        creator: j['creator'] == null
            ? null
            : UserBrief.fromJson(j['creator'] as Map<String, dynamic>),
        createdAt: j['createdAt'] == null
            ? null
            : DateTime.tryParse(j['createdAt']),
      );
}

class ScheduleBrief {
  final int id;
  final String title;
  ScheduleBrief({required this.id, required this.title});
  factory ScheduleBrief.fromJson(Map<String, dynamic> j) =>
      ScheduleBrief(id: (j['id'] as num).toInt(), title: (j['title'] ?? '') as String);
}
