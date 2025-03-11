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

    // 디자이너 목록
    final designersList = List<Designer>.from(designers);

    // 인턴 시프트 밸런스 초기화
    final internShiftBalance = _initializeInternShiftBalance(interns, previousInternBalance);

    // 각 날짜별 스케줄 생성
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);

      // 주말(금,토,일) 확인
      final isWeekend = date.weekday >= 5; // 5=금, 6=토, 7=일

      // 해당 날짜에 휴무가 아닌 디자이너 필터링
      final availableDesigners = designersList.where((d) =>
      !d.daysOff.any((off) =>
      off.year == date.year &&
          off.month == date.month &&
          off.day == date.day
      )
      ).toList();

      // 공평한 순번 배분을 위해 디자이너 순서 결정
      // 이 부분을 수정하여 한 날짜에 모든 디자이너를 순번대로 배치
      final designerTurnOrder = _assignDesignersForDay(availableDesigners, date, day);

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
    final designerBalanceCarryover = _calculateDesignerBalanceCarryover(designersList);
    final internShiftBalanceCarryover = _calculateInternShiftBalanceCarryover(internShiftBalance);

    return schedule.copyWith(
      designerBalanceCarryover: designerBalanceCarryover,
      internShiftBalanceCarryover: internShiftBalanceCarryover,
    );
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

  // 하루에 모든 디자이너 배정 (순번 공평 배분)
  List<Designer> _assignDesignersForDay(
      List<Designer> availableDesigners,
      DateTime date,
      int dayOfMonth,
      ) {
    if (availableDesigners.isEmpty) return [];

    // 각 날짜마다 디자이너 순번 순서를 다르게 하여 공평하게 배분
    // 날짜를 기준으로 시작 위치 결정
    final startIndex = (dayOfMonth - 1) % availableDesigners.length;

    // 결과 리스트 생성
    final result = <Designer>[];

    // 시작 위치부터 끝까지
    for (int i = 0; i < availableDesigners.length; i++) {
      final index = (startIndex + i) % availableDesigners.length;
      final designer = availableDesigners[index];
      // 순번 업데이트 (위치+1이 순번)
      designer.turnOrder = i + 1;
      result.add(designer);
    }

    return result;
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
      // 현재 순번 상태 그대로 이월
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