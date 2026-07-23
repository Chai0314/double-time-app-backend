/// 首页概览数据
import 'schedule_model.dart' show UserBrief;

class Overview {
  final int todaySchedules;
  final int todayTodoAll;
  final int todayTodoDone;
  final int monthSchedules;
  final List<Completion> completion;
  final int? anniversaryDays;
  final UserBrief? userA;
  final UserBrief? userB;

  Overview({
    required this.todaySchedules,
    required this.todayTodoAll,
    required this.todayTodoDone,
    required this.monthSchedules,
    required this.completion,
    this.anniversaryDays,
    this.userA,
    this.userB,
  });

  factory Overview.fromJson(Map<String, dynamic> j) {
    final today = (j['today'] ?? {}) as Map<String, dynamic>;
    return Overview(
      todaySchedules: (today['schedules'] ?? 0) as int,
      todayTodoAll: (today['todoAll'] ?? 0) as int,
      todayTodoDone: (today['todoDone'] ?? 0) as int,
      monthSchedules: (j['monthSchedules'] ?? 0) as int,
      completion: ((j['completion'] ?? []) as List)
          .map((e) => Completion.fromJson(e as Map<String, dynamic>))
          .toList(),
      anniversaryDays: j['anniversaryDays'] == null
          ? null
          : (j['anniversaryDays'] as num).toInt(),
      userA: j['userA'] == null
          ? null
          : UserBrief.fromJson(j['userA'] as Map<String, dynamic>),
      userB: j['userB'] == null
          ? null
          : UserBrief.fromJson(j['userB'] as Map<String, dynamic>),
    );
  }
}

class Completion {
  final UserBrief user;
  final int total;
  final int done;
  final int rate;
  Completion({
    required this.user,
    required this.total,
    required this.done,
    required this.rate,
  });
  factory Completion.fromJson(Map<String, dynamic> j) => Completion(
        user: UserBrief.fromJson(j['user'] as Map<String, dynamic>),
        total: (j['total'] ?? 0) as int,
        done: (j['done'] ?? 0) as int,
        rate: (j['rate'] ?? 0) as int,
      );
}

class MessageItem {
  final int id;
  final String type;
  final String title;
  final String content;
  final String refType;
  final int? refId;
  final int isRead;
  final DateTime? createdAt;
  final UserBrief? sender;

  MessageItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.refType,
    this.refId,
    required this.isRead,
    this.createdAt,
    this.sender,
  });

  factory MessageItem.fromJson(Map<String, dynamic> j) => MessageItem(
        id: (j['id'] as num).toInt(),
        type: (j['type'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        content: (j['content'] ?? '') as String,
        refType: (j['refType'] ?? '') as String,
        refId:
            j['refId'] == null ? null : (j['refId'] as num).toInt(),
        isRead: (j['isRead'] ?? 0) as int,
        createdAt: j['createdAt'] == null
            ? null
            : DateTime.tryParse(j['createdAt']),
        sender: j['sender'] == null
            ? null
            : UserBrief.fromJson(j['sender'] as Map<String, dynamic>),
      );
}
