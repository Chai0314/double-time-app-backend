import '../../core/api/api_client.dart';
import '../models/schedule_model.dart';

class ScheduleRepository {
  final ApiClient _api = ApiClient();

  Future<List<Schedule>> list({int? year, int? month}) async {
    Map<String, dynamic>? q;
    if (year != null && month != null) {
      q = {'view': 'month', 'year': year, 'month': month};
    }
    final list = await _api.get<List<dynamic>>(
      '/api/schedules',
      query: q,
      parse: (d) => d as List<dynamic>,
    );
    return list.map((e) => Schedule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Schedule>> today() async {
    final list = await _api.get<List<dynamic>>(
      '/api/schedules/today',
      parse: (d) => d as List<dynamic>,
    );
    return list.map((e) => Schedule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Schedule> detail(int id) async {
    final j = await _api.get<Map<String, dynamic>>(
      '/api/schedules/$id',
      parse: (d) => d as Map<String, dynamic>,
    );
    return Schedule.fromJson(j);
  }

  Future<Schedule> create(Map<String, dynamic> data) async {
    final j = await _api.post<Map<String, dynamic>>(
      '/api/schedules',
      data: data,
      parse: (d) => d as Map<String, dynamic>,
    );
    return Schedule.fromJson(j);
  }

  Future<Schedule> update(int id, Map<String, dynamic> data) async {
    final j = await _api.put<Map<String, dynamic>>(
      '/api/schedules/$id',
      data: data,
      parse: (d) => d as Map<String, dynamic>,
    );
    return Schedule.fromJson(j);
  }

  Future<void> remove(int id) async {
    await _api.delete<Map<String, dynamic>>(
      '/api/schedules/$id',
      parse: (_) => <String, dynamic>{},
    );
  }

  /// 月视图标记：date -> count
  Future<Map<DateTime, int>> calendar(int year, int month) async {
    final list = await _api.get<List<dynamic>>(
      '/api/schedules/calendar',
      query: {'year': year, 'month': month},
      parse: (d) => d as List<dynamic>,
    );
    final out = <DateTime, int>{};
    for (final e in list) {
      final m = e as Map<String, dynamic>;
      final d = DateTime.parse(m['date'] as String);
      out[DateTime(d.year, d.month, d.day)] = (m['count'] as num).toInt();
    }
    return out;
  }
}
