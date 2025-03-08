import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/designer.dart';
import '../models/intern.dart';
import '../models/schedule.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'calendar_screen.dart';
import 'staff_screen.dart';
import 'scheduler_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _screens = [
      const CalendarScreen(),
      const StaffScreen(),
      const SchedulerScreen(),
      const SettingsScreen(),
    ];
    _loadInitialData();
  }

  // 초기 데이터 로드
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);

      // 디자이너 데이터 로드
      final designers = await storageService.loadDesigners();
      Provider.of<DesignerProvider>(context, listen: false).setDesigners(designers);

      // 인턴 데이터 로드
      final interns = await storageService.loadInterns();
      Provider.of<InternProvider>(context, listen: false).setInterns(interns);

      // 현재 월의 스케줄 로드
      final now = DateTime.now();
      final currentSchedule = await storageService.loadMonthlySchedule(now.year, now.month);
      if (currentSchedule != null) {
        Provider.of<ScheduleProvider>(context, listen: false).setSchedule(currentSchedule);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터 로드 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appTitle),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(AppIcons.calendar),
            label: AppStrings.calendarPage,
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.designer),
            label: AppStrings.staffPage,
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.generate),
            label: AppStrings.schedulerPage,
          ),
          BottomNavigationBarItem(
            icon: Icon(AppIcons.settings),
            label: AppStrings.settingsPage,
          ),
        ],
      ),
    );
  }
}