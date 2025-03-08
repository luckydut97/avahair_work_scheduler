import '../models/designer.dart';
import '../models/intern.dart';
import '../models/schedule.dart';
import '../models/shift.dart';

class SchedulerService {
  // 월간 스케줄 자동 생성
  MonthlySchedule generateMonthlySchedule({
    required int year,
    required int month,
    required List<Designer> designers,
    required List<Intern> interns,
    Map<String, int>? previousDesignerBalance,
    Map<String, Map<ShiftType, int>>? previousInternBalance,
  }) {
    final schedule = MonthlySchedule.createEmpty(year, month);
    final daysInMonth = _getDaysInMonth(year, month);

    // 디자이너 순번 로테이션 초기화
    final designerRotation = _initializeDesignerRotation(designers);

    // 인턴 시프트 밸런스 초기화
    final internShiftBalance = _initializeInternShiftBalance(interns, previousInternBalance);

    // 각 날짜별 스케줄 생성
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);

      // 주말(금,토,일) 확인
      final isWeekend = date.weekday >= 5; // 5=금, 6=토, 7=일

      // 디자이너 순번 계산
      final availableDesigners = designers.where((d) =>
      !d.daysOff.any((off) =>
      off.year == date.year &&
          off.month == date.month &&
          off.day == date.day
      )
      ).toList();

      // 디자이너 순번 배정
      final designerTurnOrder = _assignDesignerTurn(availableDesigners, designerRotation);

      // 인턴 시프트 배정 (주말만)
      Map<String, ShiftType> internShifts = {};
      if (isWeekend) {
        internShifts = _assignInternShifts(date, interns, internShiftBalance);
      }

      // 해당 날짜의 스케줄 저장
      final dayShift = DayShift(
        date: date,
        internShifts: internShifts,
        designerTurnOrder: designerTurnOrder.map((d) => d.id).toList(),
      );

      schedule.dayShifts[_dateToString(date)] = dayShift;
    }

    // 다음 달로 이월될 밸런스 계산
    final designerBalanceCarryover = _calculateDesignerBalanceCarryover(designers);
    final internShiftBalanceCarryover = _calculateInternShiftBalanceCarryover(internShiftBalance);

    return schedule.copyWith(
      designerBalanceCarryover: designerBalanceCarryover,
      internShiftBalanceCarryover: internShiftBalanceCarryover,
    );
  }

  // 디자이너 순번 초기화
  List<Designer> _initializeDesignerRotation(List<Designer> designers) {
    // 순번 순서대로 정렬
    final sortedDesigners = List<Designer>.from(designers);
    sortedDesigners.sort((a, b) => a.turnOrder.compareTo(b.turnOrder));
    return sortedDesigners;
  }

  // 인턴 시프트 밸런스 초기화
  Map<String, Map<ShiftType, int>> _initializeInternShiftBalance(
      List<Intern> interns,
      Map<String, Map<ShiftType, int>>? previousBalance,
      ) {
    final balance = <String, Map<ShiftType, int>>{};

    for (final intern in interns) {
      balance[intern.id] = {
        ShiftType.morning: 0,
        ShiftType.afternoon: 0,
      };

      // 이전 달의 밸런스가 있으면 반영
      if (previousBalance != null && previousBalance.containsKey(intern.id)) {
        balance[intern.id]![ShiftType.morning] =
            previousBalance[intern.id]![ShiftType.morning] ?? 0;
        balance[intern.id]![ShiftType.afternoon] =
            previousBalance[intern.id]![ShiftType.afternoon] ?? 0;
      }
    }

    return balance;
  }

  // 디자이너 순번 배정
  List<Designer> _assignDesignerTurn(
      List<Designer> availableDesigners,
      List<Designer> designerRotation,
      ) {
    // 현재 순번대로 정렬된 디자이너 목록에서 휴무가 아닌 디자이너만 선택
    final workingDesigners = designerRotation.where((d) =>
        availableDesigners.any((a) => a.id == d.id)
    ).toList();

    // 다음 순번 계산 (1234 -> 2341 -> 3412 -> 4123 패턴)
    if (workingDesigners.isNotEmpty) {
      final firstDesigner = workingDesigners.removeAt(0);
      workingDesigners.add(firstDesigner);
    }

    // 순번대로 정렬된 결과 반환
    return workingDesigners;
  }

  // 인턴 시프트 배정 (오전/오후)
  Map<String, ShiftType> _assignInternShifts(
      DateTime date,
      List<Intern> interns,
      Map<String, Map<ShiftType, int>> shiftBalance,
      ) {
    final shifts = <String, ShiftType>{};

    // 해당 날짜에 휴무가 아닌 인턴 필터링
    final availableInterns = interns.where((intern) =>
    !intern.daysOff.any((off) =>
    off.year == date.year &&
        off.month == date.month &&
        off.day == date.day
    )
    ).toList();

    if (availableInterns.isEmpty) return shifts;

    // 오전/오후 배정을 위해 인턴 정렬 (오전/오후 근무 횟수 차이가 큰 순서대로)
    availableInterns.sort((a, b) {
      final aBalance = (shiftBalance[a.id]![ShiftType.morning] ?? 0) -
          (shiftBalance[a.id]![ShiftType.afternoon] ?? 0);
      final bBalance = (shiftBalance[b.id]![ShiftType.morning] ?? 0) -
          (shiftBalance[b.id]![ShiftType.afternoon] ?? 0);
      return bBalance.compareTo(aBalance);
    });

    // 오전 시프트는 오전 근무 수가 적은 인턴에게 배정
    if (availableInterns.isNotEmpty) {
      final morningIntern = availableInterns[0];
      shifts[morningIntern.id] = ShiftType.morning;
      shiftBalance[morningIntern.id]![ShiftType.morning] =
          (shiftBalance[morningIntern.id]![ShiftType.morning] ?? 0) + 1;
    }

    // 오후 시프트는 오후 근무 수가 적은 인턴에게 배정
    if (availableInterns.length > 1) {
      final afternoonIntern = availableInterns[1];
      shifts[afternoonIntern.id] = ShiftType.afternoon;
      shiftBalance[afternoonIntern.id]![ShiftType.afternoon] =
          (shiftBalance[afternoonIntern.id]![ShiftType.afternoon] ?? 0) + 1;
    }

    return shifts;
  }

  // 디자이너 밸런스 이월 계산
  Map<String, int> _calculateDesignerBalanceCarryover(List<Designer> designers) {
    final balanceCarryover = <String, int>{};

    for (final designer in designers) {
      // 디자이너 순번에 따른 밸런스 계산
      // 순번이 뒤로 갈수록 이월 밸런스에 유리하게 적용
      balanceCarryover[designer.id] = designer.turnOrder;
    }

    return balanceCarryover;
  }

  // 인턴 시프트 밸런스 이월 계산
  Map<String, Map<ShiftType, int>> _calculateInternShiftBalanceCarryover(
      Map<String, Map<ShiftType, int>> shiftBalance,
      ) {
    // 단순히 현재 밸런스를 그대로 다음 달로 이월
    return Map<String, Map<ShiftType, int>>.from(shiftBalance);
  }

  // 날짜를 "YYYY-MM-DD" 형식의 문자열로 변환
  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 해당 월의 일수 계산
  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}