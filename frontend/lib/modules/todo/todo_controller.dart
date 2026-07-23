import 'package:get/get.dart';

import '../../core/api/api_error.dart';
import '../../core/api/socket_service.dart';
import '../../data/models/todo_model.dart';
import '../../data/repositories/todo_repository.dart';
import '../auth/auth_controller.dart';

class TodoController extends GetxController {
  final TodoRepository _repo = TodoRepository();

  final RxList<Todo> todos = <Todo>[].obs;
  final RxString filter = 'all'.obs; // all / mine / partner
  final RxBool loading = false.obs;

  // 分工统计
  final RxInt mineTotal = 0.obs;
  final RxInt partnerTotal = 0.obs;
  final RxInt commonTotal = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _bindSocket();
    refreshList();
  }

  void _bindSocket() {
    SocketService().events.listen((e) {
      if (e.name == 'todo_update') {
        refreshList();
      }
    });
  }

  int _myId() => Get.find<AuthController>().user?.id ?? 0;

  Future<void> refreshList() async {
    // 仅在「首次加载且无数据」时显示 loading，避免切换 tab 时整页闪动
    if (todos.isEmpty) loading.value = true;
    try {
      final list = await _repo.list(filter: filter.value);
      todos.assignAll(list);
      // 统计：所有任务（不过滤）
      final all = await _repo.list();
      final me = _myId();
      mineTotal.value = all
          .where((t) => t.executor != null && t.executor!.id == me)
          .length;
      partnerTotal.value = all
          .where((t) => t.executor != null && t.executor!.id != me)
          .length;
      commonTotal.value = all.where((t) => t.executor == null).length;
    } catch (_) {} finally {
      loading.value = false;
    }
  }

  Future<void> setFilter(String f) async {
    if (filter.value == f) return;
    filter.value = f;
    // 切 tab 时不切换 loading，保留旧数据直到新数据到达
    try {
      final list = await _repo.list(filter: f);
      todos.assignAll(list);
    } catch (_) {}
  }

  Future<void> toggleComplete(Todo t) async {
    try {
      await _repo.update(t.id, {
        'status': t.status == 2 ? 0 : 2,
      });
      await refreshList();
    } catch (e) {
      showError(e, title: '操作失败');
    }
  }

  Future<void> createTodo(Map<String, dynamic> data) async {
    await _repo.create(data);
    await refreshList();
  }

  Future<void> updateTodo(int id, Map<String, dynamic> data) async {
    await _repo.update(id, data);
    await refreshList();
  }

  Future<void> deleteTodo(int id) async {
    await _repo.remove(id);
    await refreshList();
  }
}
