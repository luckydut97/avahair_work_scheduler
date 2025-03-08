import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('설정', style: AppTextStyles.title),
            const SizedBox(height: 24),

            // 이전 스케줄 관리
            const Text('스케줄 관리', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            _buildPreviousScheduleList(context),

            const SizedBox(height: 24),

            // 앱 정보
            const Text('앱 정보', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('아바헤어 스케줄러', style: AppTextStyles.body),
                    const Text('버전: 1.0.0', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 8),
                    const Text('© 2025 아바헤어', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _showAboutDialog(context),
                        child: const Text('앱 정보'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 이전 스케줄 목록 위젯
  Widget _buildPreviousScheduleList(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: Provider.of<StorageService>(context).getRecentSchedules(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('오류가 발생했습니다: ${snapshot.error}'),
            ),
          );
        }

        final recentSchedules = snapshot.data ?? [];

        if (recentSchedules.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('저장된 스케줄이 없습니다.'),
            ),
          );
        }

        return Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentSchedules.length,
            itemBuilder: (context, index) {
              final scheduleKey = recentSchedules[index];
              // 키 형식 "schedule_YYYY_MM" 에서 연도와 월 추출
              final parts = scheduleKey.split('_');
              if (parts.length >= 3) {
                final year = int.tryParse(parts[1]) ?? DateTime.now().year;
                final month = int.tryParse(parts[2]) ?? DateTime.now().month;
                final date = DateTime(year, month);

                return ListTile(
                  title: Text(DateHelper.formatYearMonth(date)),
                  subtitle: const Text('스케줄 데이터'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDeleteSchedule(context, year, month),
                  ),
                  onTap: () => _loadSchedule(context, year, month),
                );
              }

              return const SizedBox();
            },
          ),
        );
      },
    );
  }

  // 스케줄 삭제 확인 다이얼로그
  void _confirmDeleteSchedule(BuildContext context, int year, int month) {
    final date = DateTime(year, month);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('스케줄 삭제'),
        content: Text('${DateHelper.formatYearMonth(date)} 스케줄을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSchedule(context, year, month);
            },
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  // 스케줄 삭제
  Future<void> _deleteSchedule(BuildContext context, int year, int month) async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      await storageService.deleteMonthlySchedule(year, month);

      // 현재 표시된 스케줄이 삭제된 스케줄인 경우 초기화
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      final currentSchedule = scheduleProvider.currentSchedule;
      if (currentSchedule != null &&
          currentSchedule.year == year &&
          currentSchedule.month == month) {
        scheduleProvider.setSchedule(null);
      }

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('스케줄이 삭제되었습니다.')),
      );
    } catch (e) {
      // 오류 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('스케줄 삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // 스케줄 불러오기
  Future<void> _loadSchedule(BuildContext context, int year, int month) async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);

      final schedule = await storageService.loadMonthlySchedule(year, month);
      if (schedule != null) {
        scheduleProvider.setSchedule(schedule);

        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스케줄이 로드되었습니다.')),
        );
      }
    } catch (e) {
      // 오류 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('스케줄 로드 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // 앱 정보 다이얼로그
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '아바헤어 스케줄러',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(AppIcons.calendar, size: 48, color: AppColors.primary),
      applicationLegalese: '© 2025 아바헤어 All rights reserved.',
      children: [
        const SizedBox(height: 24),
        const Text(
          '아바헤어 직원 스케줄 관리를 위한 앱입니다.\n'
              '디자이너와 인턴의 근무 일정을 자동으로 생성하고 관리할 수 있습니다.\n\n'
              '특징:\n'
              '- 디자이너 순번 자동 관리\n'
              '- 인턴 오전/오후 근무 공평 배분\n'
              '- 휴무일 자동 반영\n'
              '- 스케줄 공유 기능',
        ),
      ],
    );
  }
}