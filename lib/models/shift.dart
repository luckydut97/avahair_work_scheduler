enum ShiftType {
  none,
  morning, // 오전
  afternoon, // 오후
}

class DayShift {
  final DateTime date;
  final Map<String, ShiftType> internShifts; // 인턴 ID -> 근무 타입
  final List<String> designerTurnOrder; // 디자이너 ID 순서

  DayShift({
    required this.date,
    required this.internShifts,
    required this.designerTurnOrder,
  });

  Map<String, dynamic> toJson() {
    final shiftsMap = <String, String>{};
    internShifts.forEach((key, value) {
      shiftsMap[key] = value.toString().split('.').last;
    });

    return {
      'date': date.toIso8601String(),
      'internShifts': shiftsMap,
      'designerTurnOrder': designerTurnOrder,
    };
  }

  factory DayShift.fromJson(Map<String, dynamic> json) {
    final shiftsMap = <String, ShiftType>{};
    (json['internShifts'] as Map<String, dynamic>).forEach((key, value) {
      shiftsMap[key] = ShiftType.values.firstWhere(
            (e) => e.toString().split('.').last == value,
        orElse: () => ShiftType.none,
      );
    });

    return DayShift(
      date: DateTime.parse(json['date']),
      internShifts: shiftsMap,
      designerTurnOrder: List<String>.from(json['designerTurnOrder']),
    );
  }
}