import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4A90E2);
  static const secondary = Color(0xFFFF6B6B);
  static const background = Color(0xFFF5F7FA);
  static const text = Color(0xFF333333);
  static const textLight = Color(0xFF757575);
  static const morningShift = Color(0xFFAED581); // 오전 근무 색상
  static const afternoonShift = Color(0xFF90CAF9); // 오후 근무 색상
  static const offDay = Color(0xFFFFCDD2); // 휴무일 색상
}

class AppTextStyles {
  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.text,
  );

  static const bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.textLight,
  );

  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class AppStrings {
  static const appTitle = '에이바헤어 직원 스케줄러';
  static const homePage = '홈';
  static const calendarPage = '캘린더';
  static const staffPage = '스태프 관리';
  static const schedulerPage = '스케줄 생성';
  static const settingsPage = '설정';

  static const morningShift = '오전';
  static const afternoonShift = '오후';
  static const dayOff = '휴무';

  static const designer = '디자이너';
  static const intern = '인턴';

  static const save = '저장';
  static const cancel = '취소';
  static const edit = '수정';
  static const delete = '삭제';
  static const share = '공유';
  static const generate = '생성';

  static const noStaff = '등록된 스태프가 없습니다.';
  static const noSchedule = '스케줄이 생성되지 않았습니다.';
}

class AppIcons {
  static const morning = Icons.wb_sunny_outlined;
  static const afternoon = Icons.nights_stay_outlined;
  static const dayOff = Icons.event_busy;
  static const designer = Icons.content_cut;
  static const intern = Icons.person;
  static const calendar = Icons.calendar_today;
  static const settings = Icons.settings;
  static const generate = Icons.auto_awesome;
  static const share = Icons.share;
  static const add = Icons.add;
  static const edit = Icons.edit;
  static const delete = Icons.delete;
}