import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/shift.dart';
import 'constants.dart';

class DateHelper {
  // 날짜 포맷 (YYYY년 MM월)
  static String formatYearMonth(DateTime date) {
    return DateFormat('yyyy년 MM월', 'ko_KR').format(date);
  }

  // 날짜 포맷 (YYYY-MM-DD)
  static String formatDateISO(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // 날짜 포맷 (MM월 DD일 E요일)
  static String formatDateWithDay(DateTime date) {
    return DateFormat('MM월 dd일 EEEE', 'ko_KR').format(date);
  }

  // 날짜 포맷 (HH:MM)
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  // 다음 달 가져오기
  static DateTime getNextMonth(DateTime date) {
    if (date.month == 12) {
      return DateTime(date.year + 1, 1);
    } else {
      return DateTime(date.year, date.month + 1);
    }
  }

  // 이전 달 가져오기
  static DateTime getPreviousMonth(DateTime date) {
    if (date.month == 1) {
      return DateTime(date.year - 1, 12);
    } else {
      return DateTime(date.year, date.month - 1);
    }
  }

  // 두 날짜가 같은 날인지 확인
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // 두 날짜가 같은 달인지 확인
  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  // 주말인지 확인 (금,토,일)
  static bool isWeekend(DateTime date) {
    return date.weekday >= 5; // 5=금, 6=토, 7=일
  }
}

class ShiftHelper {
  // 시프트 타입에 따른 색상 가져오기
  static Color getShiftColor(ShiftType type) {
    switch (type) {
      case ShiftType.morning:
        return AppColors.morningShift;
      case ShiftType.afternoon:
        return AppColors.afternoonShift;
      default:
        return Colors.transparent;
    }
  }

  // 시프트 타입에 따른 아이콘 가져오기
  static IconData getShiftIcon(ShiftType type) {
    switch (type) {
      case ShiftType.morning:
        return AppIcons.morning;
      case ShiftType.afternoon:
        return AppIcons.afternoon;
      default:
        return Icons.help_outline;
    }
  }

  // 시프트 타입에 따른 텍스트 가져오기
  static String getShiftText(ShiftType type) {
    switch (type) {
      case ShiftType.morning:
        return AppStrings.morningShift;
      case ShiftType.afternoon:
        return AppStrings.afternoonShift;
      default:
        return '';
    }
  }
}

class IDGenerator {
  // 고유 ID 생성
  static String generate() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}