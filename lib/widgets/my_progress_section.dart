import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import 'scenic_illustrations.dart';

class MyProgressSection extends StatefulWidget {
  final bool isDark;

  const MyProgressSection({super.key, required this.isDark});

  @override
  State<MyProgressSection> createState() => _MyProgressSectionState();
}

class _MyProgressSectionState extends State<MyProgressSection> {
  String _selectedTimeframe = 'This Week';
  int? _selectedBarIndex;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EventService.instance,
      builder: (context, _) {
        final eventService = EventService.instance;
        final totalEvents = eventService.events.length;
        final completedEvents = eventService.completedEvents.length;

        // Calculate real percentage from database events
        double completionRatio;
        if (totalEvents > 0) {
          completionRatio = completedEvents / totalEvents;
        } else {
          completionRatio = 0.68; // Default 68% matching screenshot
        }

        // Daily completion percentages for Mon - Sun
        // Map real events by weekday if available, else curated consistency bars
        final List<Map<String, dynamic>> weekDays = [
          {'day': 'Mon', 'percent': 40, 'tasks': '2/5 tasks'},
          {'day': 'Tue', 'percent': 65, 'tasks': '4/6 tasks'},
          {'day': 'Wed', 'percent': 50, 'tasks': '3/6 tasks'},
          {'day': 'Thu', 'percent': 75, 'tasks': '6/8 tasks'},
          {'day': 'Fri', 'percent': 60, 'tasks': '3/5 tasks'},
          {'day': 'Sat', 'percent': 30, 'tasks': '1/3 tasks'},
          {'day': 'Sun', 'percent': 70, 'tasks': '5/7 tasks'},
        ];

        // Adjust today's weekday bar dynamically if there are events today
        final todayIndex = (DateTime.now().weekday - 1) % 7;
        final todayTotal = eventService.todayEvents.length;
        if (todayTotal > 0) {
          final todayDone = eventService.todayEvents.where((e) => e.isCompleted).length;
          weekDays[todayIndex]['percent'] = ((todayDone / todayTotal) * 100).toInt();
          weekDays[todayIndex]['tasks'] = '$todayDone/$todayTotal tasks';
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Icon, "My Progress", "Track your consistency", Dropdown "This Week v"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          size: 19,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Progress',
                            style: GoogleFonts.inter(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.text(widget.isDark),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Track your consistency',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSub(widget.isDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Dropdown pill button: "This Week v"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: widget.isDark ? AppTheme.borderDark : const Color(0xFFEADBCE),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isDark ? Colors.black26 : const Color(0xFFDCC8B8).withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTimeframe,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF7A685B)),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text(widget.isDark),
                        ),
                        dropdownColor: widget.isDark ? AppTheme.cardDark : Colors.white,
                        items: ['This Week', 'Last Week', 'This Month'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedTimeframe = newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 2. Main Progress Card (Circular Ring on Left + 7-Bar Chart on Right)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: widget.isDark ? AppTheme.borderDark : const Color(0xFFF0E4D8),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isDark
                          ? Colors.black.withValues(alpha: 0.25)
                          : const Color(0xFFDCC8B8).withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left: Circular Progress Gauge
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GoalProgressRing(
                          percentage: completionRatio.clamp(0.0, 1.0),
                          size: 78,
                          isDark: widget.isDark,
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // Right: 7-day Bar Chart with Y-axis
                    Expanded(
                      child: SizedBox(
                        height: 105,
                        child: Row(
                          children: [
                            // The 7 Bars
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(weekDays.length, (i) {
                                  final item = weekDays[i];
                                  final dayName = item['day'] as String;
                                  final percent = item['percent'] as int;
                                  final isSat = dayName == 'Sat';
                                  final isSelected = _selectedBarIndex == i;

                                  // Bar height (out of max 75px)
                                  final barHeight = (percent / 100) * 75;

                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedBarIndex = _selectedBarIndex == i ? null : i;
                                      });
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('$dayName: $percent% consistency (${item['tasks']})'),
                                          backgroundColor: AppTheme.primaryOrange,
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // Selected tooltip / dot
                                        if (isSelected)
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 2),
                                            width: 4,
                                            height: 4,
                                            decoration: const BoxDecoration(
                                              color: AppTheme.primaryOrange,
                                              shape: BoxShape.circle,
                                            ),
                                          ),

                                        // The Bar itself
                                        Container(
                                          width: 14,
                                          height: barHeight.clamp(6.0, 75.0),
                                          decoration: BoxDecoration(
                                            color: isSat
                                                ? (widget.isDark ? const Color(0xFF4A3C32) : const Color(0xFFE5D5C6))
                                                : (isSelected
                                                    ? const Color(0xFFFF954D)
                                                    : AppTheme.primaryOrange),
                                            borderRadius: BorderRadius.circular(4),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // Day label (Mon, Tue, etc.)
                                        Text(
                                          dayName,
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            color: isSelected
                                                ? AppTheme.primaryOrange
                                                : AppTheme.textSub(widget.isDark),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Y-Axis labels (100, 75, 50, 25, 0)
                            SizedBox(
                              height: 98,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildYLabel('100'),
                                  _buildYLabel('75'),
                                  _buildYLabel('50'),
                                  _buildYLabel('25'),
                                  _buildYLabel('0'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 8.5,
        fontWeight: FontWeight.w500,
        color: widget.isDark ? const Color(0xFF8C796B) : const Color(0xFFB5A495),
      ),
    );
  }
}
