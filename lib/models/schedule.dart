import 'package:flutter/foundation.dart';
import 'shift.dart';

class MonthlySchedule {
  final int year;
  final int month;
  final Map<String, DayShift> dayShifts; // 날짜 문자열 -> 해당 날짜 스케줄
  final Map<String, int> designerBalanceCarryover; // 디자이너 ID -> 다음 달로 이월되는 밸런스
  final Map<String, Map<ShiftType, int>> internShiftBalanceCarryover; // 인턴 ID -> 시프트 타입 -> 다음 달로 이월되는 밸런스

  MonthlySchedule({
    required this.year,
    required this.month,
    required this.dayShifts,
    required this.designerBalanceCarryover,
    required this.internShiftBalanceCarryover,
  });

  Map<String, dynamic> toJson() {
    final shiftsMap = <String, dynamic>{};
    dayShifts.forEach((key, value) {
      shiftsMap[key] = value.toJson();
    });

    final internBalanceMap = <String, Map<String, int>>{};
    internShiftBalanceCarryover.forEach((internId, balances) {
      internBalanceMap[internId] = {};
      balances.forEach((shiftType, count) {
        internBalanceMap[internId]![shiftType.toString().split('.').last] = count;
      });
    });

    return {
      'year': year,
      'month': month,
      'dayShifts': shiftsMap,
      'designerBalanceCarryover': designerBalanceCarryover,
      'internShiftBalanceCarryover': internBalanceMap,
    };
  }

  factory MonthlySchedule.fromJson(Map<String, dynamic> json) {
    final shiftsMap = <String, DayShift>{};
    (json['dayShifts'] as Map<String, dynamic>).forEach((key, value) {
      shiftsMap[key] = DayShift.fromJson(value as Map<String, dynamic>);
    });

    final designerBalance = <String, int>{};
    (json['designerBalanceCarryover'] as Map<String, dynamic>).forEach((key, value) {
      designerBalance[key] = value as int;
    });

    final internBalanceMap = <String, Map<ShiftType, int>>{};
    (json['internShiftBalanceCarryover'] as Map<String, dynamic>).forEach((internId, balances) {
      internBalanceMap[internId] = {};
      (balances as Map<String, dynamic>).forEach((shiftTypeStr, count) {
        final shiftType = ShiftType.values.firstWhere(
              (e) => e.toString().split('.').last == shiftTypeStr,
          orElse: () => ShiftType.none,
        );
        internBalanceMap[internId]![shiftType] = count as int;
      });
    });

    return MonthlySchedule(
      year: json['year'],
      month: json['month'],
      dayShifts: shiftsMap,
      designerBalanceCarryover: designerBalance,
      internShiftBalanceCarryover: internBalanceMap,
    );
  }

  MonthlySchedule copyWith({
    int? year,
    int? month,
    Map<String, DayShift>? dayShifts,
    Map<String, int>? designerBalanceCarryover,
    Map<String, Map<ShiftType, int>>? internShiftBalanceCarryover,
  }) {
    return MonthlySchedule(
      year: year ?? this.year,
      month: month ?? this.month,
      dayShifts: dayShifts ?? this.dayShifts,
      designerBalanceCarryover: designerBalanceCarryover ?? this.designerBalanceCarryover,
      internShiftBalanceCarryover: internShiftBalanceCarryover ?? this.internShiftBalanceCarryover,
    );
  }

  // 새 빈 월간 스케줄 생성
  static MonthlySchedule createEmpty(int year, int month) {
    return MonthlySchedule(
      year: year,
      month: month,
      dayShifts: {},
      designerBalanceCarryover: {},
      internShiftBalanceCarryover: {},
    );
  }
}

class ScheduleProvider with ChangeNotifier {
  MonthlySchedule? _currentSchedule;

  MonthlySchedule? get currentSchedule => _currentSchedule;

  void setSchedule(MonthlySchedule? schedule) {
    _currentSchedule = schedule;
    notifyListeners();
  }

  void updateDayShift(DayShift dayShift) {
    if (_currentSchedule == null) return;

    final dateStr = _dateToString(dayShift.date);
    final updatedDayShifts = Map<String, DayShift>.from(_currentSchedule!.dayShifts);
    updatedDayShifts[dateStr] = dayShift;

    _currentSchedule = _currentSchedule!.copyWith(
      dayShifts: updatedDayShifts,
    );

    notifyListeners();
  }

  DayShift? getDayShift(DateTime date) {
    if (_currentSchedule == null) return null;

    final dateStr = _dateToString(date);
    return _currentSchedule!.dayShifts[dateStr];
  }

  // 특정 날짜의 디자이너 순번 가져오기
  List<String>? getDesignerTurnOrder(DateTime date) {
    final dayShift = getDayShift(date);
    return dayShift?.designerTurnOrder;
  }

  // 특정 날짜의 인턴 시프트 가져오기
  Map<String, ShiftType>? getInternShifts(DateTime date) {
    final dayShift = getDayShift(date);
    return dayShift?.internShifts;
  }

  // 날짜를 "YYYY-MM-DD" 형식의 문자열로 변환
  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}