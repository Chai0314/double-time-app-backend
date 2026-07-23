import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/api/socket_service.dart';
import '../../data/models/schedule_model.dart';
import '../../data/repositories/schedule_repository.dart';

class ScheduleController extends GetxController {
  final ScheduleRepository _repo = ScheduleRepository();

  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rx<DateTime> selectedDay = DateTime.now().obs;
  final Rx<CalendarFormat> format = CalendarFormat.month.obs;
  final RxMap<DateTime, int> eventMarker = <DateTime, int>{}.obs;
  final RxList<Schedule> daySchedules = <Schedule>[].obs;
  final RxList<Schedule> allSchedules = <Schedule>[].obs;
  final RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _bindSocket();
    loadMonth(DateTime.now().year, DateTime.now().month);
    loadDay(DateTime.now());
  }

  void _bindSocket() {
    SocketService().events.listen((e) {
      if (e.name == 'schedule_update') {
        loadMonth(focusedDay.value.year, focusedDay.value.month);
        loadDay(selectedDay.value);
      }
    });
  }

  Future<void> loadMonth(int y, int m) async {
    final map = await _repo.calendar(y, m);
    eventMarker.assignAll(map);
  }

  Future<void> loadDay(DateTime day) async {
    loading.value = true;
    try {
      // 当日 = 月份视图里所有日程的过滤
      final all = await _repo.list(year: day.year, month: day.month);
      allSchedules.assignAll(all);
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      daySchedules.assignAll(
        all.where((s) {
          final st = s.startTime.toLocal();
          return !st.isBefore(start) && st.isBefore(end);
        }),
      );
    } finally {
      loading.value = false;
    }
  }

  void onPageChanged(DateTime focused) {
    focusedDay.value = focused;
    loadMonth(focused.year, focused.month);
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay.value = selected;
    focusedDay.value = focused;
    loadDay(selected);
  }

  Future<void> createSchedule(Map<String, dynamic> data) async {
    await _repo.create(data);
    await loadMonth(focusedDay.value.year, focusedDay.value.month);
    await loadDay(selectedDay.value);
  }

  Future<void> updateSchedule(int id, Map<String, dynamic> data) async {
    await _repo.update(id, data);
    await loadMonth(focusedDay.value.year, focusedDay.value.month);
    await loadDay(selectedDay.value);
  }

  Future<void> deleteSchedule(int id) async {
    await _repo.remove(id);
    await loadMonth(focusedDay.value.year, focusedDay.value.month);
    await loadDay(selectedDay.value);
  }
}
