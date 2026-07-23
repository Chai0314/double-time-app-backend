import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/stats_model.dart';
import '../../data/repositories/stats_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final StatsRepository _repo = StatsRepository();
  List<MessageItem>? _list;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.messages();
    final count = await _repo.unreadCount();
    setState(() {
      _list = list;
      _unread = count;
    });
  }

  Future<void> _readAll() async {
    await _repo.readAll();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('消息通知'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_unread > 0)
            TextButton(
              onPressed: _readAll,
              child: const Text('全部已读',
                  style: TextStyle(color: AppTheme.primary)),
            ),
        ],
      ),
      body: _list == null
          ? const Center(child: CircularProgressIndicator())
          : _list!.isEmpty
              ? const Center(
                  child: Text('暂无消息',
                      style: TextStyle(color: AppTheme.textSecondary)),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _list!.length,
                    separatorBuilder: (c, i) => const Divider(
                        height: 1, color: Color(0xFFEEEEEE), indent: 60),
                    itemBuilder: (c, i) {
                      final m = _list![i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: m.isRead == 1
                              ? AppTheme.bgColor
                              : AppTheme.primary.withOpacity(0.2),
                          child: Icon(
                            _iconFor(m.type),
                            color: m.isRead == 1
                                ? AppTheme.textSecondary
                                : AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(m.title,
                            style: TextStyle(
                              fontWeight: m.isRead == 1
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            )),
                        subtitle: Text(m.content,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Text(
                          m.createdAt == null
                              ? ''
                              : DateFormat('MM-dd HH:mm')
                                  .format(m.createdAt!.toLocal()),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        onTap: () async {
                          if (m.isRead == 0) {
                            await _repo.read(m.id);
                            await _load();
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }

  IconData _iconFor(String t) {
    switch (t) {
      case 'schedule':
        return Icons.calendar_today;
      case 'todo':
        return Icons.check_circle_outline;
      case 'media':
        return Icons.image;
      case 'couple':
        return Icons.favorite;
      default:
        return Icons.notifications;
    }
  }
}
