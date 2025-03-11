import 'package:flutter/foundation.dart';

class Designer {
  final String id;
  final String name;
  List<DateTime> daysOff; // 휴무일
  int turnOrder; // 초기 순번 (스케줄 생성 시 재배정됨)

  Designer({
    required this.id,
    required this.name,
    required this.daysOff,
    this.turnOrder = 0, // 기본값 0으로 변경 (의미 없는 값)
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'daysOff': daysOff.map((date) => date.toIso8601String()).toList(),
      'turnOrder': turnOrder,
    };
  }

  factory Designer.fromJson(Map<String, dynamic> json) {
    return Designer(
      id: json['id'],
      name: json['name'],
      daysOff: (json['daysOff'] as List).map((date) => DateTime.parse(date)).toList(),
      turnOrder: json['turnOrder'] ?? 0,
    );
  }

  Designer copyWith({
    String? id,
    String? name,
    List<DateTime>? daysOff,
    int? turnOrder,
  }) {
    return Designer(
      id: id ?? this.id,
      name: name ?? this.name,
      daysOff: daysOff ?? this.daysOff,
      turnOrder: turnOrder ?? this.turnOrder,
    );
  }
}

class DesignerProvider with ChangeNotifier {
  List<Designer> _designers = [];

  List<Designer> get designers => _designers;

  void setDesigners(List<Designer> designers) {
    _designers = designers;
    notifyListeners();
  }

  void addDesigner(Designer designer) {
    _designers.add(designer);
    notifyListeners();
  }

  void updateDesigner(Designer designer) {
    final index = _designers.indexWhere((d) => d.id == designer.id);
    if (index != -1) {
      _designers[index] = designer;
      notifyListeners();
    }
  }

  void removeDesigner(String id) {
    _designers.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  void updateTurnOrder(List<String> orderedIds) {
    for (int i = 0; i < orderedIds.length; i++) {
      final designer = _designers.firstWhere((d) => d.id == orderedIds[i]);
      designer.turnOrder = i + 1;
    }
    notifyListeners();
  }

  List<Designer> getDesignersInTurnOrder() {
    final sortedDesigners = List<Designer>.from(_designers);
    sortedDesigners.sort((a, b) => a.turnOrder.compareTo(b.turnOrder));
    return sortedDesigners;
  }

  // 특정 날짜에 휴무가 아닌 디자이너 목록 가져오기
  List<Designer> getAvailableDesigners(DateTime date) {
    return _designers.where((designer) {
      return !designer.daysOff.any((daysOff) =>
      daysOff.year == date.year &&
          daysOff.month == date.month &&
          daysOff.day == date.day
      );
    }).toList();
  }
}