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
            // 캘린더 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateHelper.formatYearMonth(_focusedDay),
                    style: AppTextStyles.title,
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
              calendarStyle: CalendarStyle(
                outsideDaysVisible: true,
                weekendTextStyle: const TextStyle(color: AppColors.secondary),
                holidayTextStyle: const TextStyle(color: AppColors.secondary),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  return _buildCalendarDayMarkers(context, date);
                },
              ),
            ),
            const Divider(),
            // 선택한 날짜의 상세 정보
            _buildSelectedDayDetail(),
          ],
        ),
      ),
    );
  }

  // 캘린더 날짜 마커 (스케줄 정보 표시)
  Widget? _buildCalendarDayMarkers(BuildContext context, DateTime date) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final dayShift = scheduleProvider.getDayShift(date);

    if (dayShift == null) return null;

    final designerProvider = Provider.of<DesignerProvider>(context);

    // 해당 날짜의 디자이너 순번 정보
    final designerTurnOrder = dayShift.designerTurnOrder;

    if (designerTurnOrder.isEmpty) return null;

    // Get the designer name instead of showing the ID
    final designerId = designerTurnOrder[0];
    final designer = designerProvider.designers.firstWhere(
          (d) => d.id == designerId,
      orElse: () => Designer(
        id: designerId,
        name: '?',
        daysOff: [],
        turnOrder: 1,
      ),
    );

    // Display designer's name or first letter instead of ID
    final displayText = designer.name.isNotEmpty ? designer.name[0] : '?';

    // 마커 UI 구성
    return Positioned(
      bottom: 1,
      child: Container(
        width: 40,
        height: 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DateHelper.isWeekend(date) ? AppColors.secondary.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          displayText, // Display first letter of name instead of ID
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                  Text(
                    DateHelper.formatDateWithDay(_selectedDay!),
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 16),
                  // 디자이너 순번 정보
                  const Text('디자이너 순번', style: AppTextStyles.subtitle),
                  const SizedBox(height: 8),
                  _buildDesignerTurnList(dayShift, designerProvider),
                  const SizedBox(height: 16),
                  // 인턴 시프트 정보 (주말인 경우만)
                  if (DateHelper.isWeekend(_selectedDay!)) ...[
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
  Widget _buildDesignerTurnList(DayShift? dayShift, DesignerProvider designerProvider) {
    if (dayShift == null || dayShift.designerTurnOrder.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('스케줄이 생성되지 않았습니다.'),
        ),
      );
    }

    return Card(
      child: Container( // 컨테이너로 감싸서 크기 제한
        constraints: BoxConstraints(maxHeight: 200), // 최대 높이 설정
        child: ListView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(), // 스크롤 가능하도록 변경
          itemCount: dayShift.designerTurnOrder.length,
          itemBuilder: (context, index) {
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

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(designer.name),
              subtitle: Text('순번: ${designer.turnOrder}'),
            );
          },
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
      child: Container( // 컨테이너로 감싸서 크기 제한
        constraints: BoxConstraints(maxHeight: 200), // 최대 높이 설정
        child: ListView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(), // 스크롤 가능하도록 변경
          itemCount: dayShift.internShifts.length,
          itemBuilder: (context, index) {
            final entry = dayShift.internShifts.entries.elementAt(index);
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

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: ShiftHelper.getShiftColor(shiftType),
                child: Icon(
                  ShiftHelper.getShiftIcon(shiftType),
                  color: Colors.white,
                ),
              ),
              title: Text(intern.name),
              subtitle: Text(ShiftHelper.getShiftText(shiftType)),
            );
          },
        ),
      ),
    );
  }
}