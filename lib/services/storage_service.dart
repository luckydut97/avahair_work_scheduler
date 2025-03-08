import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/designer.dart';
import '../models/intern.dart';
import '../models/schedule.dart';

class StorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 디자이너 저장
  Future<void> saveDesigners(List<Designer> designers) async {
    final designersJson = designers.map((designer) => jsonEncode(designer.toJson())).toList();
    await _prefs.setStringList('designers', designersJson);
  }

  // 디자이너 불러오기
  Future<List<Designer>> loadDesigners() async {
    final designersJson = _prefs.getStringList('designers');
    if (designersJson == null) return [];

    return designersJson
        .map((designerJson) => Designer.fromJson(jsonDecode(designerJson)))
        .toList();
  }

  // 인턴 저장
  Future<void> saveInterns(List<Intern> interns) async {
    final internsJson = interns.map((intern) => jsonEncode(intern.toJson())).toList();
    await _prefs.setStringList('interns', internsJson);
  }

  // 인턴 불러오기
  Future<List<Intern>> loadInterns() async {
    final internsJson = _prefs.getStringList('interns');
    if (internsJson == null) return [];

    return internsJson
        .map((internJson) => Intern.fromJson(jsonDecode(internJson)))
        .toList();
  }

  // 월간 스케줄 저장
  Future<void> saveMonthlySchedule(MonthlySchedule schedule) async {
    final scheduleKey = 'schedule_${schedule.year}_${schedule.month}';
    final scheduleJson = jsonEncode(schedule.toJson());
    await _prefs.setString(scheduleKey, scheduleJson);

    // 최근 스케줄 목록 업데이트
    final recentSchedules = _prefs.getStringList('recent_schedules') ?? [];
    if (!recentSchedules.contains(scheduleKey)) {
      recentSchedules.add(scheduleKey);
      await _prefs.setStringList('recent_schedules', recentSchedules);
    }
  }

  // 월간 스케줄 불러오기
  Future<MonthlySchedule?> loadMonthlySchedule(int year, int month) async {
    final scheduleKey = 'schedule_${year}_${month}';
    final scheduleJson = _prefs.getString(scheduleKey);
    if (scheduleJson == null) return null;

    return MonthlySchedule.fromJson(jsonDecode(scheduleJson));
  }

  // 최근 스케줄 목록 불러오기
  Future<List<String>> getRecentSchedules() async {
    return _prefs.getStringList('recent_schedules') ?? [];
  }

  // 스케줄 삭제
  Future<void> deleteMonthlySchedule(int year, int month) async {
    final scheduleKey = 'schedule_${year}_${month}';
    await _prefs.remove(scheduleKey);

    // 최근 스케줄 목록에서 제거
    final recentSchedules = _prefs.getStringList('recent_schedules') ?? [];
    recentSchedules.remove(scheduleKey);
    await _prefs.setStringList('recent_schedules', recentSchedules);
  }
}