import 'package:get/get.dart';

import '../../core/api/socket_service.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/todo_model.dart';
import '../../data/models/stats_model.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/repositories/todo_repository.dart';
import '../auth/auth_controller.dart';

class HomeController extends GetxController {
  final ScheduleRepository _scheduleRepo = ScheduleRepository();
  final TodoRepository _todoRepo = TodoRepository();
  final StatsRepository _statsRepo = StatsRepository();

  final Rx<Overview?> overview = Rx<Overview?>(null);
  final RxList<Schedule> todaySchedules = <Schedule>[].obs;
  final RxList<Todo> todayTodos = <Todo>[].obs;
  final RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _bindSocket();
    // 当前用户（昵称/头像/纪念日）变更时，自动刷新首页概览
    if (Get.isRegistered<AuthController>()) {
      ever(Get.find<AuthController>().currentUser, (_) => refreshAll());
    }
    refreshAll();
  }

  void _bindSocket() {
    SocketService().events.listen((e) {
      if (e.name == 'schedule_update' || e.name == 'todo_update') {
        refreshAll();
      }
    });
  }

  Future<void> refreshAll() async {
    loading.value = true;
    try {
      final results = await Future.wait([
        _statsRepo.overview(),
        _scheduleRepo.today(),
        _todoRepo.list(),
      ]);
      overview.value = results[0] as Overview;
      todaySchedules.assignAll(results[1] as List<Schedule>);
      // 仅展示今日范围
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      final list = (results[2] as List<Todo>).where((t) {
        if (t.deadline == null) return false;
        return t.deadline!.isAfter(start) && t.deadline!.isBefore(end);
      }).toList();
      todayTodos.assignAll(list);
    } catch (_) {
      // ignore
    } finally {
      loading.value = false;
    }
  }
}
