import '../../core/api/api_client.dart';
import '../models/stats_model.dart';

class StatsRepository {
  final ApiClient _api = ApiClient();

  Future<Overview> overview() async {
    final j = await _api.get<Map<String, dynamic>>(
      '/api/stats/overview',
      parse: (d) => d as Map<String, dynamic>,
    );
    return Overview.fromJson(j);
  }

  Future<List<MessageItem>> messages({bool unreadOnly = false}) async {
    final list = await _api.get<List<dynamic>>(
      '/api/messages',
      query: unreadOnly ? {'unread': 1} : null,
      parse: (d) => d as List<dynamic>,
    );
    return list
        .map((e) => MessageItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final j = await _api.get<Map<String, dynamic>>(
      '/api/messages/unread-count',
      parse: (d) => d as Map<String, dynamic>,
    );
    return (j['count'] ?? 0) as int;
  }

  Future<void> readAll() async {
    await _api.put<Map<String, dynamic>>(
      '/api/messages/read-all',
      parse: (d) => d as Map<String, dynamic>,
    );
  }

  Future<void> read(int id) async {
    await _api.put<Map<String, dynamic>>(
      '/api/messages/$id/read',
      parse: (d) => d as Map<String, dynamic>,
    );
  }
}
