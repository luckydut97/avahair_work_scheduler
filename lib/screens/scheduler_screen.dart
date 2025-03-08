import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/designer.dart';
import '../models/intern.dart';
import '../models/schedule.dart';
import '../services/scheduler_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({Key? key}) : super(key: key);

  @override
  _SchedulerScreenState createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  final SchedulerService _schedulerService = SchedulerService();
  bool _isGenerating = false;
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            const Text('스케줄 생성', style: AppTextStyles.title),
            const SizedBox(height: 24),

            // 월 선택
            _buildMonthSelector(),
            const SizedBox(height: 24),

            // 스태프 요약 정보
            _buildStaffSummary(),
            const SizedBox(height: 24),

            // 생성 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isGenerating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('스케줄 생성하기', style: AppTextStyles.button),
              ),
            ),
            const SizedBox(height: 16),

            // 안내 텍스트
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('스케줄 생성 시 유의사항:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• 디자이너 순번은 공평하게 배분됩니다.'),
                  Text('• 인턴은 금/토/일에만 오전/오후 근무가 배정됩니다.'),
                  Text('• 각 스태프의 휴무일은 자동으로 반영됩니다.'),
                  Text('• 생성 후에도 개별 수정 가능합니다.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 월 선택 위젯
  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateHelper.getPreviousMonth(_selectedMonth);
                });
              },
            ),
            Text(
              DateHelper.formatYearMonth(_selectedMonth),
              style: AppTextStyles.subtitle,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateHelper.getNextMonth(_selectedMonth);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // 스태프 요약 정보 위젯
  Widget _buildStaffSummary() {
    return Consumer2<DesignerProvider, InternProvider>(
      builder: (context, designerProvider, internProvider, child) {
        final designers = designerProvider.designers;
        final interns = internProvider.interns;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('스태프 현황', style: AppTextStyles.subtitle),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        icon: AppIcons.designer,
                        title: '디자이너',
                        count: designers.length,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        icon: AppIcons.intern,
                        title: '인턴',
                        count: interns.length,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (designers.isEmpty || interns.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.withOpacity(0.1),
                    child: const Text(
                      '스케줄 생성을 위해서는 최소 1명 이상의 디자이너와 인턴이 필요합니다.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 요약 아이템 위젯
  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(title, style: AppTextStyles.body),
        Text('$count명', style: AppTextStyles.subtitle),
      ],
    );
  }

  // 스케줄 생성 로직
  Future<void> _generateSchedule() async {
    final designerProvider = Provider.of<DesignerProvider>(context, listen: false);
    final internProvider = Provider.of<InternProvider>(context, listen: false);
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    final designers = designerProvider.designers;
    final interns = internProvider.interns;

    if (designers.isEmpty || interns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('스케줄 생성을 위해서는 최소 1명 이상의 디자이너와 인턴이 필요합니다.')),
      );
      return;
    }

    // 스케줄 생성 시작
    setState(() {
      _isGenerating = true;
    });

    try {
      // 이전 달 스케줄 체크 (이월 데이터 확인)
      final prevMonth = DateHelper.getPreviousMonth(_selectedMonth);
      final prevSchedule = await storageService.loadMonthlySchedule(
        prevMonth.year,
        prevMonth.month,
      );

      // 스케줄 생성
      final schedule = _schedulerService.generateMonthlySchedule(
        year: _selectedMonth.year,
        month: _selectedMonth.month,
        designers: designers,
        interns: interns,
        previousDesignerBalance: prevSchedule?.designerBalanceCarryover,
        previousInternBalance: prevSchedule?.internShiftBalanceCarryover,
      );

      // 생성된 스케줄 저장
      await storageService.saveMonthlySchedule(schedule);

      // 현재 Provider에 스케줄 설정
      scheduleProvider.setSchedule(schedule);

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('스케줄 생성이 완료되었습니다.')),
      );
    } catch (e) {
      // 오류 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('스케줄 생성 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
}