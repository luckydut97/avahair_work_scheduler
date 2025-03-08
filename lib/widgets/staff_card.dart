import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/designer.dart';
import '../models/intern.dart';
import '../models/shift.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

// 디자이너 카드 위젯
class DesignerCard extends StatefulWidget {
  final Designer designer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(DateTime) onDayOffChange;

  const DesignerCard({
    Key? key,
    required this.designer,
    required this.onEdit,
    required this.onDelete,
    required this.onDayOffChange,
  }) : super(key: key);

  @override
  _DesignerCardState createState() => _DesignerCardState();
}

class _DesignerCardState extends State<DesignerCard> {
  bool _isExpanded = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // 카드 헤더
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                widget.designer.name.isNotEmpty ? widget.designer.name[0] : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(widget.designer.name),
            subtitle: Text('순번: ${widget.designer.turnOrder}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(AppIcons.edit),
                  onPressed: widget.onEdit,
                ),
                IconButton(
                  icon: const Icon(AppIcons.delete),
                  onPressed: widget.onDelete,
                ),
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          // 확장 영역 (캘린더)
          if (_isExpanded)
            SingleChildScrollView( // 여기에 SingleChildScrollView 추가
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('휴무일 선택', style: AppTextStyles.subtitle),
                    ),
                    Container( // 캘린더를 Container로 감싸 크기 제한
                      height: 320, // 캘린더 높이 제한
                      child: TableCalendar(
                        firstDay: DateTime.utc(2023, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) {
                          // 휴무일로 선택된 날짜 표시
                          return widget.designer.daysOff.any((d) => DateHelper.isSameDay(d, day));
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          widget.onDayOffChange(selectedDay);
                        },
                        onFormatChanged: (format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarStyle: CalendarStyle(
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.offDay,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(color: AppColors.text),
                          todayDecoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// 인턴 카드 위젯
class InternCard extends StatefulWidget {
  final Intern intern;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(DateTime) onDayOffChange;

  const InternCard({
    Key? key,
    required this.intern,
    required this.onEdit,
    required this.onDelete,
    required this.onDayOffChange,
  }) : super(key: key);

  @override
  _InternCardState createState() => _InternCardState();
}

class _InternCardState extends State<InternCard> {
  bool _isExpanded = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    // 현재 달의 오전/오후 근무 횟수 계산
    final now = DateTime.now();
    final shiftCounts = widget.intern.getShiftCounts(now.year, now.month);
    final morningCount = shiftCounts[ShiftType.morning] ?? 0;
    final afternoonCount = shiftCounts[ShiftType.afternoon] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // 카드 헤더
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.secondary,
              child: Text(
                widget.intern.name.isNotEmpty ? widget.intern.name[0] : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(widget.intern.name),
            subtitle: Text('오전: $morningCount회, 오후: $afternoonCount회'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(AppIcons.edit),
                  onPressed: widget.onEdit,
                ),
                IconButton(
                  icon: const Icon(AppIcons.delete),
                  onPressed: widget.onDelete,
                ),
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          // 확장 영역 (캘린더)
          if (_isExpanded)
            SingleChildScrollView( // 여기에 SingleChildScrollView 추가
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('휴무일 선택', style: AppTextStyles.subtitle),
                    ),
                    Container( // 캘린더를 Container로 감싸 크기 제한
                      height: 320, // 캘린더 높이 제한
                      child: TableCalendar(
                        firstDay: DateTime.utc(2023, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) {
                          // 휴무일로 선택된 날짜 표시
                          return widget.intern.daysOff.any((d) => DateHelper.isSameDay(d, day));
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          widget.onDayOffChange(selectedDay);
                        },
                        onFormatChanged: (format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarStyle: CalendarStyle(
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.offDay,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(color: AppColors.text),
                          todayDecoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}