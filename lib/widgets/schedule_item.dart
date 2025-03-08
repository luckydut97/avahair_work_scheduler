import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/designer.dart';
import '../models/intern.dart';
import '../models/shift.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ScheduleDayItem extends StatelessWidget {
  final DateTime date;
  final List<String> designerTurnOrder;
  final Map<String, ShiftType> internShifts;
  final VoidCallback? onEdit;

  const ScheduleDayItem({
    Key? key,
    required this.date,
    required this.designerTurnOrder,
    required this.internShifts,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWeekend = DateHelper.isWeekend(date);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateHelper.formatDateWithDay(date),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isWeekend ? AppColors.secondary : AppColors.text,
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(AppIcons.edit, size: 18),
                    onPressed: onEdit,
                  ),
              ],
            ),
            const Divider(),

            // 디자이너 순번
            if (designerTurnOrder.isNotEmpty) ...[
              const Text('디자이너 순번:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              _buildDesignerTurns(context),
              const SizedBox(height: 8),
            ],

            // 인턴 시프트 (주말인 경우만)
            if (isWeekend && internShifts.isNotEmpty) ...[
              const Text('인턴 시프트:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              _buildInternShifts(context),
            ],
          ],
        ),
      ),
    );
  }

  // 디자이너 순번 목록 위젯
  Widget _buildDesignerTurns(BuildContext context) {
    return Consumer<DesignerProvider>(
      builder: (context, designerProvider, child) {
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: designerTurnOrder.asMap().entries.map((entry) {
            final index = entry.key;
            final designerId = entry.value;
            final designer = designerProvider.designers.firstWhere(
                  (d) => d.id == designerId,
              orElse: () => Designer(
                id: designerId,
                name: '알 수 없음',
                daysOff: [],
                turnOrder: index + 1,
              ),
            );

            return Chip(
              avatar: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
              label: Text(designer.name),
              backgroundColor: AppColors.primary.withOpacity(0.1),
            );
          }).toList(),
        );
      },
    );
  }

  // 인턴 시프트 목록 위젯
  Widget _buildInternShifts(BuildContext context) {
    return Consumer<InternProvider>(
      builder: (context, internProvider, child) {
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: internShifts.entries.map((entry) {
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

            return Chip(
              avatar: CircleAvatar(
                backgroundColor: ShiftHelper.getShiftColor(shiftType),
                child: Icon(
                  ShiftHelper.getShiftIcon(shiftType),
                  size: 12,
                  color: Colors.white,
                ),
              ),
              label: Text('${intern.name} (${ShiftHelper.getShiftText(shiftType)})'),
              backgroundColor: ShiftHelper.getShiftColor(shiftType).withOpacity(0.1),
            );
          }).toList(),
        );
      },
    );
  }
}

class MonthSummaryItem extends StatelessWidget {
  final int year;
  final int month;
  final int designerCount;
  final int internCount;
  final VoidCallback onTap;

  const MonthSummaryItem({
    Key? key,
    required this.year,
    required this.month,
    required this.designerCount,
    required this.internCount,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = DateTime(year, month);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateHelper.formatYearMonth(date),
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildCountItem(AppIcons.designer, '디자이너', designerCount),
                  const SizedBox(width: 24),
                  _buildCountItem(AppIcons.intern, '인턴', internCount),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountItem(IconData icon, String label, int count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 4),
        Text('$label: $count명', style: AppTextStyles.bodySmall),
      ],
    );
  }
}