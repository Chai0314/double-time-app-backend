import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();

  Future<({String token, User user})> login({
    required String account,
    required String password,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'account': account, 'password': password},
      parse: (d) => d as Map<String, dynamic>,
    );
    final token = data['token'] as String;
    await ApiClient.setToken(token);
    return (
      token: token,
      user: User.fromJson(data['user'] as Map<String, dynamic>)
    );
  }

  /// 运营商本机一键登录（手机号+运营商token）
  Future<({String token, User user})> phoneOneClickLogin({
    required String phone,
    required String carrierToken,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/auth/phone-one-click',
      data: {'phone': phone, 'carrierToken': carrierToken},
      parse: (d) => d as Map<String, dynamic>,
    );
    final token = data['token'] as String;
    await ApiClient.setToken(token);
    return (
      token: token,
      user: User.fromJson(data['user'] as Map<String, dynamic>)
    );
  }

  /// 注册（手机号+密码）
  Future<({String token, User user})> register({
    required String account,
    required String password,
    String? nickname,
    String? avatar,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {
        'account': account,
        'password': password,
        if (nickname != null) 'nickname': nickname,
        if (avatar != null) 'avatar': avatar,
      },
      parse: (d) => d as Map<String, dynamic>,
    );
    final token = data['token'] as String;
    await ApiClient.setToken(token);
    return (
      token: token,
      user: User.fromJson(data['user'] as Map<String, dynamic>)
    );
  }

  Future<({String token, User user})> wxLogin({
    required String openid,
    String? nickname,
    String? avatar,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/auth/wx-login',
      data: {
        'openid': openid,
        if (nickname != null) 'nickname': nickname,
        if (avatar != null) 'avatar': avatar,
      },
      parse: (d) => d as Map<String, dynamic>,
    );
    final token = data['token'] as String;
    await ApiClient.setToken(token);
    return (
      token: token,
      user: User.fromJson(data['user'] as Map<String, dynamic>)
    );
  }

  Future<User> me() async {
    final j = await _api.get<Map<String, dynamic>>(
      '/api/auth/me',
      parse: (d) => d as Map<String, dynamic>,
    );
    return User.fromJson(j);
  }

  Future<User> updateMe(Map<String, dynamic> patch) async {
    final j = await _api.put<Map<String, dynamic>>(
      '/api/auth/me',
      data: patch,
      parse: (d) => d as Map<String, dynamic>,
    );
    return User.fromJson(j);
  }

  /// 上传头像，返回 { avatar: '/uploads/avatars/xxx', user: User }
  /// 跨平台：传入 XFile，内部 readAsBytes
  Future<({String avatar, User user})> uploadAvatar(XFile file) async {
    final bytes = await file.readAsBytes();
    final j = await _api.uploadBytes<Map<String, dynamic>>(
      '/api/auth/avatar',
      bytes: bytes,
      filename: file.name,
      parse: (d) => d as Map<String, dynamic>,
    );
    return (
      avatar: (j['avatar'] ?? '') as String,
      user: User.fromJson(j['user'] as Map<String, dynamic>),
    );
  }

  /// 修改密码
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _api.post<Map<String, dynamic>>(
      '/api/auth/change-password',
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      parse: (d) => d as Map<String, dynamic>,
    );
  }

  Future<String> createInvite() async {
    final j = await _api.post<Map<String, dynamic>>(
      '/api/couple/invite',
      parse: (d) => d as Map<String, dynamic>,
    );
    return j['inviteCode'] as String;
  }

  Future<int> bind(String inviteCode) async {
    final j = await _api.post<Map<String, dynamic>>(
      '/api/couple/bind',
      data: {'inviteCode': inviteCode},
      parse: (d) => d as Map<String, dynamic>,
    );
    return (j['coupleId'] as num).toInt();
  }

  Future<void> unbind() async {
    await _api.post<Map<String, dynamic>>(
      '/api/couple/unbind',
      parse: (d) => d as Map<String, dynamic>,
    );
  }

  Future<CoupleInfo> coupleInfo() async {
    final j = await _api.get<Map<String, dynamic>>(
      '/api/couple/info',
      parse: (d) => d as Map<String, dynamic>,
    );
    return CoupleInfo.fromJson(j);
  }

  Future<List<User>> members() async {
    final list = await _api.get<List<dynamic>>(
      '/api/couple/members',
      parse: (d) => d as List<dynamic>,
    );
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }
}
