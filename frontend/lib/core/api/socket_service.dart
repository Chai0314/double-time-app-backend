import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../api/api_client.dart';
import '../config/env.dart';

/// Socket.io 单例：登录后连接，绑定 coupleId 后切换房间
class SocketService {
  static final SocketService _instance = SocketService._();
  factory SocketService() => _instance;

  IO.Socket? _socket;
  final _eventCtrl = StreamController<SocketEvent>.broadcast();

  Stream<SocketEvent> get events => _eventCtrl.stream;

  bool get isConnected => _socket?.connected ?? false;

  SocketService._();

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;
    final token = await ApiClient.getToken();
    if (token == null || token.isEmpty) return;
    _socket = IO.io(
      Env.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!
      ..onConnect((_) => _emit(SocketEvent('connect', {})))
      ..onDisconnect((_) => _emit(SocketEvent('disconnect', {})))
      ..on('schedule_update',
          (data) => _emit(SocketEvent('schedule_update', data)))
      ..on('media_update', (data) => _emit(SocketEvent('media_update', data)))
      ..on('todo_update', (data) => _emit(SocketEvent('todo_update', data)))
      ..on('message_push',
          (data) => _emit(SocketEvent('message_push', data)));

    _socket!.connect();
  }

  void bindCouple(int coupleId) {
    _socket?.emit('bind_couple', coupleId);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void _emit(SocketEvent e) {
    _eventCtrl.add(e);
  }
}

class SocketEvent {
  final String name;
  final dynamic data;
  SocketEvent(this.name, this.data);
}
