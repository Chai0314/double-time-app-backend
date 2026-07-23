import '../../core/api/api_client.dart';
import '../models/todo_model.dart';

class TodoRepository {
  final ApiClient _api = ApiClient();

  Future<List<Todo>> list({String? filter, int? status}) async {
    final list = await _api.get<List<dynamic>>(
      '/api/todos',
      query: {
        if (filter != null) 'filter': filter,
        if (status != null) 'status': status,
      },
      parse: (d) => d as List<dynamic>,
    );
    return list.map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Todo> create(Map<String, dynamic> data) async {
    final j = await _api.post<Map<String, dynamic>>(
      '/api/todos',
      data: data,
      parse: (d) => d as Map<String, dynamic>,
    );
    return Todo.fromJson(j);
  }

  Future<Todo> update(int id, Map<String, dynamic> data) async {
    final j = await _api.put<Map<String, dynamic>>(
      '/api/todos/$id',
      data: data,
      parse: (d) => d as Map<String, dynamic>,
    );
    return Todo.fromJson(j);
  }

  Future<void> remove(int id) async {
    await _api.delete<Map<String, dynamic>>(
      '/api/todos/$id',
      parse: (_) => <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> stats() async {
    final j = await _api.get<Map<String, dynamic>>(
      '/api/todos/stats',
      parse: (d) => d as Map<String, dynamic>,
    );
    return j;
  }
}
