import 'package:flutter/foundation.dart';
import 'shift.dart';

class Intern {
  final String id;
  final String name;
  List<DateTime> daysOff; // 휴무일
  Map<String, ShiftType> monthlyShifts; // 날짜별 근무 타입 (오전/오후)

  Intern({
    required this.id,
    required this.name,
    required this.daysOff,
    required this.monthlyShifts,
  });

  Map<String, dynamic> toJson() {
    final shiftsMap = <String, String>{};
    monthlyShifts.forEach((key, value) {
      shiftsMap[key] = value.toString().split('.').last;
    });

    return {
      'id': id,
      'name': name,
      'daysOff': daysOff.map((date) => date.toIso8601String()).toList(),
      'monthlyShifts': shiftsMap,
    };
  }

  factory Intern.fromJson(Map<String, dynamic> json) {
    final shiftsMap = <String, ShiftType>{};
    (json['monthlyShifts'] as Map<String, dynamic>).forEach((key, value) {
      shiftsMap[key] = ShiftType.values.firstWhere(
            (e) => e.toString().split('.').last == value,
        orElse: () => ShiftType.none,
      );
    });

    return Intern(
      id: json['id'],
      name: json['name'],
      daysOff: (json['daysOff'] as List).map((date) => DateTime.parse(date)).toList(),
      monthlyShifts: shiftsMap,
    );
  }

  Intern copyWith({
    String? id,
    String? name,
    List<DateTime>? daysOff,
    Map<String, ShiftType>? monthlyShifts,
  }) {
    return Intern(
      id: id ?? this.id,
      name: name ?? this.name,
      daysOff: daysOff ?? this.daysOff,
      monthlyShifts: monthlyShifts ?? this.monthlyShifts,
    );
  }

  // 특정 달의 오전/오후 근무 횟수 계산
  Map<ShiftType, int> getShiftCounts(int year, int month) {
    final counts = <ShiftType, int>{};
    for (final type in ShiftType.values) {
      counts[type] = 0;
    }

    monthlyShifts.forEach((dateStr, shiftType) {
      final date = DateTime.parse(dateStr);
      if (date.year == year && date.month == month) {
        counts[shiftType] = (counts[shiftType] ?? 0) + 1;
      }
    });

    return counts;
  }
}

class InternProvider with ChangeNotifier {
  List<Intern> _interns = [];

  List<Intern> get interns => _interns;

  void setInterns(List<Intern> interns) {
    _interns = interns;
    notifyListeners();
  }

  void addIntern(Intern intern) {
    _interns.add(intern);
    notifyListeners();
  }

  void updateIntern(Intern intern) {
    final index = _interns.indexWhere((i) => i.id == intern.id);
    if (index != -1) {
      _interns[index] = intern;
      notifyListeners();
    }
  }

  void removeIntern(String id) {
    _interns.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void assignShift(String internId, DateTime date, ShiftType shiftType) {
    final intern = _interns.firstWhere((i) => i.id == internId);
    intern.monthlyShifts[date.toIso8601String()] = shiftType;
    notifyListeners();
  }

  // 특정 날짜에 휴무가 아닌 인턴 목록 가져오기
  List<Intern> getAvailableInterns(DateTime date) {
    return _interns.where((intern) {
      return !intern.daysOff.any((daysOff) =>
      daysOff.year == date.year &&
          daysOff.month == date.month &&
          daysOff.day == date.day
      );
    }).toList();
  }

  // 특정 날짜의 오전/오후 근무 인턴 가져오기
  List<Intern> getInternsForShift(DateTime date, ShiftType shiftType) {
    final dateStr = date.toIso8601String();
    return _interns.where((intern) =>
    intern.monthlyShifts[dateStr] == shiftType
    ).toList();
  }
}