import 'dart:async';

import 'package:get/get.dart';

import '../../core/api/api_client.dart';
import '../../core/api/socket_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// 全局用户状态
class AuthController extends GetxController {
  final AuthRepository _repo = AuthRepository();
  final Rxn<User> currentUser = Rxn<User>();
  final RxBool isLogin = false.obs;
  final RxBool loading = false.obs;

  /// bootstrap 是否完成（token 校验结束，无论是否登录）
  /// 用于 main.dart 等待初始路由决策
  final RxBool bootstrapped = false.obs;
  Completer<void>? _readyCompleter;

  /// 等待 bootstrap 完成（无论结果）
  Future<void> get ready {
    _readyCompleter ??= Completer<void>();
    return _readyCompleter!.future;
  }

  User? get user => currentUser.value;
  bool get hasCouple =>
      currentUser.value != null && currentUser.value!.coupleStatus == 1;

  @override
  void onInit() {
    super.onInit();
    _readyCompleter = Completer<void>();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final token = await ApiClient.getToken();
      if (token == null) return;
      try {
        final u = await _repo.me();
        currentUser.value = u;
        isLogin.value = true;
        // 连接 socket
        await SocketService().connect();
        if (u.coupleStatus == 1 && u.coupleId != null) {
          SocketService().bindCouple(u.coupleId!);
        }
      } catch (_) {
        await ApiClient.clearToken();
      }
    } finally {
      bootstrapped.value = true;
      _readyCompleter?.complete();
    }
  }

  Future<void> register({
    required String account,
    required String password,
    String? nickname,
  }) async {
    loading.value = true;
    try {
      final r = await _repo.register(
        account: account,
        password: password,
        nickname: nickname,
      );
      currentUser.value = r.user;
      isLogin.value = true;
      await SocketService().connect();
    } finally {
      loading.value = false;
    }
  }

  Future<void> login({
    required String account,
    required String password,
  }) async {
    loading.value = true;
    try {
      final r = await _repo.login(account: account, password: password);
      currentUser.value = r.user;
      isLogin.value = true;
      await SocketService().connect();
      if (r.user.coupleStatus == 1 && r.user.coupleId != null) {
        SocketService().bindCouple(r.user.coupleId!);
      }
    } finally {
      loading.value = false;
    }
  }

  /// 运营商本机一键登录
  Future<void> phoneOneClickLogin({
    required String phone,
    required String carrierToken,
  }) async {
    loading.value = true;
    try {
      final r = await _repo.phoneOneClickLogin(
        phone: phone,
        carrierToken: carrierToken,
      );
      currentUser.value = r.user;
      isLogin.value = true;
      await SocketService().connect();
      if (r.user.coupleStatus == 1 && r.user.coupleId != null) {
        SocketService().bindCouple(r.user.coupleId!);
      }
    } finally {
      loading.value = false;
    }
  }

  /// 自动读取本机手机号（运营商 SDK 鉴权）
  /// 返回 null 表示读取失败，需用户手动输入
  Future<String?> detectLocalPhoneNumber() async {
    // TODO: 接入运营商 SDK（阿里云号码认证/极验/移动认证等）
    // 这里通过平台通道获取本机号码
    // 当前为开发期模拟：返回 null 让用户手动输入
    return null;
  }

  Future<void> wxLoginMock(String openid) async {
    // 开发期使用：直接传 openid 模拟微信登录
    loading.value = true;
    try {
      final r = await _repo.wxLogin(openid: openid);
      currentUser.value = r.user;
      isLogin.value = true;
      await SocketService().connect();
      if (r.user.coupleStatus == 1 && r.user.coupleId != null) {
        SocketService().bindCouple(r.user.coupleId!);
      }
    } finally {
      loading.value = false;
    }
  }

  Future<String> createInvite() async {
    final code = await _repo.createInvite();
    await _refreshMe();
    return code;
  }

  Future<int> bind(String inviteCode) async {
    final cid = await _repo.bind(inviteCode);
    await _refreshMe();
    SocketService().bindCouple(cid);
    return cid;
  }

  Future<void> unbind() async {
    await _repo.unbind();
    await _refreshMe();
  }

  Future<void> _refreshMe() async {
    final u = await _repo.me();
    currentUser.value = u;
    if (u.coupleStatus == 1 && u.coupleId != null) {
      SocketService().bindCouple(u.coupleId!);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> patch) async {
    final u = await _repo.updateMe(patch);
    currentUser.value = u;
  }

  Future<void> logout() async {
    await ApiClient.clearToken();
    SocketService().disconnect();
    currentUser.value = null;
    isLogin.value = false;
  }
}
