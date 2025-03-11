import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:screenshot/screenshot.dart';
import '../models/designer.dart';
import '../models/intern.dart';
import '../models/schedule.dart';
import '../models/shift.dart';
import '../services/share_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final ShareService _shareService = ShareService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const SizedBox(height: 8),
            // 캘린더 헤더 (월 표시와 함께 2주 선택 옵션)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                          });
                        },
                      ),
                      Text(
                        DateHelper.formatYearMonth(_focusedDay),
                        style: AppTextStyles.title,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                          });
                        },
                      ),
                    ],
                  ),
                  // 주 선택 버튼을 오른쪽으로 이동
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _calendarFormat = _calendarFormat == CalendarFormat.month
                            ? CalendarFormat.twoWeeks
                            : CalendarFormat.month;
                      });
                    },
                    child: Text(
                      _calendarFormat == CalendarFormat.month ? '2 weeks' : 'Month',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 캘린더 위젯
            TableCalendar(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return _selectedDay != null && isSameDay(_selectedDay!, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              headerVisible: false, // 헤더 숨기기 (커스텀 헤더를 위로 이동)
              calendarStyle: CalendarStyle(
                outsideDaysVisible: true,
                weekendTextStyle: const TextStyle(color: AppColors.secondary),
                holidayTextStyle: const TextStyle(color: AppColors.secondary),
                // 캘린더 셀 높이 조정 - 충분한 공간 확보
                cellMargin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                cellPadding: EdgeInsets.zero,
                // 더 높은 셀 높이 설정
                cellAlignment: Alignment.topCenter,
              ),
              calendarBuilders: CalendarBuilders(
                // 날짜 셀 커스텀 (모든 타입의 날짜에 대해 동일한 빌더 사용)
                defaultBuilder: (context, day, focusedDay) {
                  return _buildCalendarDayCell(context, day, false, isWeekend: DateHelper.isWeekend(day));
                },
                selectedBuilder: (context, day, focusedDay) {
                  return _buildCalendarDayCell(context, day, true, isWeekend: DateHelper.isWeekend(day));
                },
                todayBuilder: (context, day, focusedDay) {
                  return _buildCalendarDayCell(context, day, false, isToday: true, isWeekend: DateHelper.isWeekend(day));
                },
                outsideBuilder: (context, day, focusedDay) {
                  return _buildCalendarDayCell(context, day, false, isOutside: true, isWeekend: DateHelper.isWeekend(day));
                },
                disabledBuilder: (context, day, focusedDay) {
                  return _buildCalendarDayCell(context, day, false, isDisabled: true, isWeekend: DateHelper.isWeekend(day));
                },
                // 주말 처리는 각 빌더 내에서 isWeekend 플래그로 처리
              ),
              // 각 날짜 셀의 높이를 설정 (디자이너 표시 공간 확보)
              rowHeight: 120, // 셀 높이 증가
            ),
            const Divider(),
            // 선택한 날짜의 상세 정보 (디자이너 순번 + 인턴 시프트)
            _buildSelectedDayDetail(),
          ],
        ),
      ),
    );
  }

  // 캘린더 날짜 셀 구성
  Widget _buildCalendarDayCell(
      BuildContext context,
      DateTime date,
      bool isSelected,
      {bool isToday = false, bool isOutside = false, bool isDisabled = false, bool isWeekend = false}
      ) {
    // 날짜 텍스트 색상
    Color textColor = isOutside ? Colors.grey.withOpacity(0.5) :
    isWeekend ? AppColors.secondary : Colors.black87;

    // 배경색
    Color backgroundColor = isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) :
    isToday ? Theme.of(context).primaryColor.withOpacity(0.1) :
    isWeekend ? AppColors.offDay.withOpacity(0.2) :
    Colors.transparent;

    // 디자이너 마커 배경색
    Color markerBackgroundColor = isWeekend ?
    AppColors.secondary.withOpacity(0.2) :
    AppColors.primary.withOpacity(0.2);

    // 디자이너 순번 정보 가져오기
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final designerProvider = Provider.of<DesignerProvider>(context);
    final dayShift = scheduleProvider.getDayShift(date);

    List<Widget> designerMarkers = [];
    if (dayShift != null && dayShift.designerTurnOrder.isNotEmpty) {
      // 디자이너 마커 생성
      designerMarkers = dayShift.designerTurnOrder.map((designerId) {
        final designer = designerProvider.designers.firstWhere(
              (d) => d.id == designerId,
          orElse: () => Designer(
            id: designerId,
            name: '?',
            daysOff: [],
            turnOrder: 0,
          ),
        );

        // 디자이너 이름 첫 글자 또는 전체 이름
        final displayText = designer.name.isNotEmpty ? designer.name[0] : '?';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Container(
            width: double.infinity,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: markerBackgroundColor,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              displayText,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList();
    }

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 날짜 표시
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          // 디자이너 마커 표시 (스크롤 가능하게)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: designerMarkers,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 선택한 날짜의 상세 정보 위젯
  Widget _buildSelectedDayDetail() {
    if (_selectedDay == null) return const SizedBox();

    return Expanded(
      child: Consumer3<ScheduleProvider, DesignerProvider, InternProvider>(
        builder: (context, scheduleProvider, designerProvider, internProvider, child) {
          final dayShift = scheduleProvider.getDayShift(_selectedDay!);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜와 공유 버튼을 나란히 배치
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateHelper.formatDateWithDay(_selectedDay!),
                        style: AppTextStyles.subtitle,
                      ),
                      IconButton(
                        icon: const Icon(AppIcons.share),
                        onPressed: () {
                          _shareService.captureWithLibraryAndShare(
                              '${DateHelper.formatYearMonth(_focusedDay)} 아바헤어 스케줄'
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 디자이너 순번 정보
                  const Text('디자이너 순번', style: AppTextStyles.subtitle),
                  const SizedBox(height: 8),
                  _buildFullDesignerTurnList(dayShift, designerProvider),

                  // 인턴 시프트 정보 (주말인 경우만)
                  if (DateHelper.isWeekend(_selectedDay!)) ...[
                    const SizedBox(height: 16),
                    const Text('인턴 근무', style: AppTextStyles.subtitle),
                    const SizedBox(height: 8),
                    _buildInternShiftList(dayShift, internProvider),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 디자이너 순번 목록 위젯
  Widget _buildFullDesignerTurnList(DayShift? dayShift, DesignerProvider designerProvider) {
    if (dayShift == null || dayShift.designerTurnOrder.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('스케줄이 생성되지 않았습니다.'),
        ),
      );
    }

    // 디자이너 전체 목록
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            dayShift.designerTurnOrder.length,
                (index) {
              final designerId = dayShift.designerTurnOrder[index];
              final designer = designerProvider.designers.firstWhere(
                    (d) => d.id == designerId,
                orElse: () => Designer(
                  id: designerId,
                  name: '알 수 없음',
                  daysOff: [],
                  turnOrder: index + 1,
                ),
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      designer.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 인턴 시프트 목록 위젯
  Widget _buildInternShiftList(DayShift? dayShift, InternProvider internProvider) {
    if (dayShift == null || dayShift.internShifts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('인턴 스케줄이 없습니다.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: dayShift.internShifts.entries.map((entry) {
            final internId = entry.key;
            final shiftType = entry.value;

            final intern = internProvider.interns.firstWhere(
                  (i) => i.id == internId,
              orElse: () => Intern(
                id: internId,
                name: '알 수 없음',
                daysOff: [],
                monthlyShifts: {},
              ),
            );

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: ShiftHelper.getShiftColor(shiftType),
                    child: Icon(
                      ShiftHelper.getShiftIcon(shiftType),
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${intern.name} (${ShiftHelper.getShiftText(shiftType)})',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}