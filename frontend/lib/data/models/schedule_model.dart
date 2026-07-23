/// 行程
class Schedule {
  final int id;
  final String title;
  final String category;
  final String address;
  final double? longitude;
  final double? latitude;
  final DateTime startTime;
  final DateTime? endTime;
  final String repeatType;
  final String? repeatEnd;
  final int remindOffset;
  final double budget;
  final double actualCost;
  final String? remark;
  final int status;
  final int isArchived;
  final UserBrief? creator;
  final List<UserBrief> members;

  Schedule({
    required this.id,
    required this.title,
    required this.category,
    required this.address,
    this.longitude,
    this.latitude,
    required this.startTime,
    this.endTime,
    required this.repeatType,
    this.repeatEnd,
    required this.remindOffset,
    required this.budget,
    required this.actualCost,
    this.remark,
    required this.status,
    required this.isArchived,
    this.creator,
    this.members = const [],
  });

  factory Schedule.fromJson(Map<String, dynamic> j) => Schedule(
        id: (j['id'] as num).toInt(),
        title: (j['title'] ?? '') as String,
        category: (j['category'] ?? 'other') as String,
        address: (j['address'] ?? '') as String,
        longitude:
            j['longitude'] == null ? null : (j['longitude'] as num).toDouble(),
        latitude:
            j['latitude'] == null ? null : (j['latitude'] as num).toDouble(),
        startTime: DateTime.parse(j['startTime'] as String),
        endTime: j['endTime'] == null ? null : DateTime.tryParse(j['endTime']),
        repeatType: (j['repeatType'] ?? 'none') as String,
        repeatEnd: j['repeatEnd'] as String?,
        remindOffset: (j['remindOffset'] ?? 0) as int,
        budget: (j['budget'] ?? 0).toDouble(),
        actualCost: (j['actualCost'] ?? 0).toDouble(),
        remark: j['remark'] as String?,
        status: (j['status'] ?? 0) as int,
        isArchived: (j['isArchived'] ?? 0) as int,
        creator: j['creator'] == null
            ? null
            : UserBrief.fromJson(j['creator'] as Map<String, dynamic>),
        members: ((j['members'] ?? []) as List)
            .map((e) => UserBrief.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String get categoryText => const {
        'date': '约会',
        'travel': '旅游',
        'home': '居家',
        'festival': '节日',
        'errand': '事务',
        'other': '其他',
      }[category] ??
      '其他';

  String get statusText => const ['待开始', '进行中', '已完成', '已取消'][status];
}

class UserBrief {
  final int id;
  final String nickname;
  final String avatar;

  UserBrief({required this.id, required this.nickname, required this.avatar});

  factory UserBrief.fromJson(Map<String, dynamic> j) => UserBrief(
        id: (j['id'] as num).toInt(),
        nickname: (j['nickname'] ?? '') as String,
        avatar: (j['avatar'] ?? '') as String,
      );
}
