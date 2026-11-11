import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/date_time_utils.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime selectedDate;
  final Set<int> daysWithEvents;
  final bool isDark;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.daysWithEvents,
    required this.isDark,
    required this.onDateSelected,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
  }

  @override
  void didUpdateWidget(covariant CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate.year != _currentMonth.year || widget.selectedDate.month != _currentMonth.month) {
      _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
    }
  }

  void _previousMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    // DateTime.weekday: 1 is Mon, 7 is Sun
    final startingWeekday = firstDayOfMonth.weekday; // 1 to 7

    final daysInPrevMonth = DateTime(_currentMonth.year, _currentMonth.month, 0).day;

    final calendarCells = <Map<String, dynamic>>[];

    // Previous month filler days
    for (int i = startingWeekday - 1; i > 0; i--) {
      calendarCells.add({
        'day': daysInPrevMonth - i + 1,
        'isCurrentMonth': false,
        'date': DateTime(_currentMonth.year, _currentMonth.month - 1, daysInPrevMonth - i + 1),
      });
    }

    // Current month days
    for (int day = 1; day <= daysInMonth; day++) {
      calendarCells.add({
        'day': day,
        'isCurrentMonth': true,
        'date': DateTime(_currentMonth.year, _currentMonth.month, day),
      });
    }

    // Trailing days to round up to complete weeks (multiple of 7)
    final remaining = (7 - (calendarCells.length % 7)) % 7;
    for (int day = 1; day <= remaining; day++) {
      calendarCells.add({
        'day': day,
        'isCurrentMonth': false,
        'date': DateTime(_currentMonth.year, _currentMonth.month + 1, day),
      });
    }

    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppTheme.softShadow(isDark),
      ),
      child: Column(
        children: [
          // Header with Month Name and Navigation Arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    DateTimeUtils.formatMonthYear(_currentMonth),
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.text(isDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: isDark ? AppTheme.textDarkSecondary : const Color(0xFF9E8E80),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _previousMonth,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2E2822) : const Color(0xFFFBF6F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: AppTheme.text(isDark),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _nextMonth,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2E2822) : const Color(0xFFFBF6F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppTheme.text(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Weekdays row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((w) {
              return SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    w,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.textDarkSecondary : const Color(0xFF8F8276),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          // Grid
          GridView.builder(
            itemCount: calendarCells.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final cell = calendarCells[index];
              final dayNum = cell['day'] as int;
              final isCurMonth = cell['isCurrentMonth'] as bool;
              final cellDate = cell['date'] as DateTime;
              final isSelected = DateTimeUtils.isSameDay(cellDate, widget.selectedDate);
              final isToday = DateTimeUtils.isSameDay(cellDate, today);
              final hasEventDot = isCurMonth && widget.daysWithEvents.contains(dayNum);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onDateSelected(cellDate);
                  if (!isCurMonth) {
                    setState(() {
                      _currentMonth = DateTime(cellDate.year, cellDate.month, 1);
                    });
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryOrange
                            : (isToday && !isSelected
                                ? (isDark ? const Color(0xFF4A3222) : const Color(0xFFFFECE0))
                                : Colors.transparent),
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(color: AppTheme.primaryOrange, width: 1.2)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNum',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w800
                                : (isCurMonth ? FontWeight.w600 : FontWeight.w400),
                            color: isSelected
                                ? Colors.white
                                : (isCurMonth
                                    ? AppTheme.text(isDark)
                                    : (isDark ? const Color(0xFF5E544A) : const Color(0xFFC7BCB0))),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Event dot
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: hasEventDot
                            ? (isSelected ? Colors.white : AppTheme.primaryOrange)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
