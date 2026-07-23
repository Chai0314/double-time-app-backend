/// 数据模型：用户
import '../../core/config/env.dart';

class User {
  final int id;
  final int? coupleId;
  final int? coupleStatus;
  final String nickname;
  final String avatar;
  final int gender;
  final String bio;
  final String? account;
  final String? phone;
  final String? anniversary;
  final String? workStart;
  final String? workEnd;
  final DateTime? createdAt;

  User({
    required this.id,
    this.coupleId,
    this.coupleStatus,
    required this.nickname,
    required this.avatar,
    this.gender = 0,
    this.bio = '',
    this.account,
    this.phone,
    this.anniversary,
    this.workStart,
    this.workEnd,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: (j['id'] as num).toInt(),
        coupleId: j['coupleId'] == null ? null : (j['coupleId'] as num).toInt(),
        coupleStatus: j['coupleStatus'] == null
            ? null
            : (j['coupleStatus'] as num).toInt(),
        nickname: (j['nickname'] ?? '') as String,
        avatar: (j['avatar'] ?? '') as String,
        gender: (j['gender'] ?? 0) as int,
        bio: (j['bio'] ?? '') as String,
        account: j['account'] as String?,
        phone: j['phone'] as String?,
        anniversary: j['anniversary'] as String?,
        workStart: j['workStart'] as String?,
        workEnd: j['workEnd'] as String?,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'coupleId': coupleId,
        'coupleStatus': coupleStatus,
        'nickname': nickname,
        'avatar': avatar,
        'gender': gender,
        'bio': bio,
        'account': account,
        'phone': phone,
        'anniversary': anniversary,
        'workStart': workStart,
        'workEnd': workEnd,
      };

  /// 头像完整 URL
  String get avatarUrl =>
      avatar.startsWith('http') ? avatar : '${Env.apiBaseUrl}$avatar';
}

/// 情侣资料聚合
class CoupleInfo {
  final int coupleId;
  final int dayCount;
  final int scheduleCount;
  final int mediaCount;
  final int todoCount;
  final List<User> members;

  CoupleInfo({
    required this.coupleId,
    required this.dayCount,
    required this.scheduleCount,
    required this.mediaCount,
    required this.todoCount,
    required this.members,
  });

  factory CoupleInfo.fromJson(Map<String, dynamic> j) => CoupleInfo(
        coupleId: (j['coupleId'] as num).toInt(),
        dayCount: (j['dayCount'] ?? 0) as int,
        scheduleCount: (j['scheduleCount'] ?? 0) as int,
        mediaCount: (j['mediaCount'] ?? 0) as int,
        todoCount: (j['todoCount'] ?? 0) as int,
        members: ((j['members'] ?? []) as List)
            .map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
