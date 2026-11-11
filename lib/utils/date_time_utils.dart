import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _fullDateTimeFormat = DateFormat('MMM dd, yyyy - hh:mm a');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return _timeFormat.format(dt);
  }

  static String formatDateTime(DateTime dateTime) {
    return _fullDateTimeFormat.format(dateTime);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  static String getRelativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    return _dateFormat.format(date);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static TimeOfDay parseTimeOfDay(String timeStr) {
    try {
      final parsed = _timeFormat.parse(timeStr.trim());
      return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    } catch (_) {
      try {
        final parts = timeStr.trim().split(':');
        final hour = int.parse(parts[0]);
        final minParts = parts[1].split(' ');
        final minute = int.parse(minParts[0]);
        var adjustedHour = hour;
        if (minParts.length > 1) {
          final isPm = minParts[1].toUpperCase() == 'PM';
          if (isPm && hour < 12) adjustedHour += 12;
          if (!isPm && hour == 12) adjustedHour = 0;
        }
        return TimeOfDay(hour: adjustedHour, minute: minute);
      } catch (_) {
        return const TimeOfDay(hour: 9, minute: 0);
      }
    }
  }

  static DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// Calculates the next occurrence for repeating reminders safely.
  /// Handles varying month lengths (Feb, Apr, etc.) without crashing.
  static DateTime getNextOccurrence({
    required DateTime currentScheduled,
    required String repeatType,
    int repeatInterval = 1,
  }) {
    final now = DateTime.now();
    DateTime next = currentScheduled;

    switch (repeatType.toLowerCase()) {
      case 'daily':
        while (!next.isAfter(now)) {
          next = next.add(const Duration(days: 1));
        }
        break;

      case 'weekly':
        while (!next.isAfter(now)) {
          next = next.add(const Duration(days: 7));
        }
        break;

      case 'monthly':
        while (!next.isAfter(now)) {
          final targetYear = next.month == 12 ? next.year + 1 : next.year;
          final targetMonth = next.month == 12 ? 1 : next.month + 1;
          final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
          final safeDay = currentScheduled.day > daysInTargetMonth ? daysInTargetMonth : currentScheduled.day;
          next = DateTime(targetYear, targetMonth, safeDay, currentScheduled.hour, currentScheduled.minute);
        }
        break;

      case 'yearly':
        while (!next.isAfter(now)) {
          final targetYear = next.year + 1;
          final daysInTargetMonth = DateTime(targetYear, currentScheduled.month + 1, 0).day;
          final safeDay = currentScheduled.day > daysInTargetMonth ? daysInTargetMonth : currentScheduled.day;
          next = DateTime(targetYear, currentScheduled.month, safeDay, currentScheduled.hour, currentScheduled.minute);
        }
        break;

      case 'custom':
        final interval = repeatInterval > 0 ? repeatInterval : 1;
        while (!next.isAfter(now)) {
          next = next.add(Duration(days: interval));
        }
        break;

      case 'none':
      default:
        break;
    }

    return next;
  }

  /// Generates a safe 32-bit positive integer notification ID from a UUID or random seed.
  static int generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(1000000000);
  }
}
