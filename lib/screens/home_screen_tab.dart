import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/app_state.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';
import '../widgets/scenic_illustrations.dart';
import '../widgets/interactive_modals.dart';
import '../widgets/my_moments_section.dart';
import '../widgets/my_progress_section.dart';
import 'add_event_screen.dart';
import 'event_details_screen.dart';

enum ReminderFilter { all, today, upcoming, completed, overdue }
enum TimeSegment { oneDay, oneMonth, onTime }
enum QuickScheduleMode { none, sun, moon, coffee, study, evening, nextWeek }

class HomeScreenTab extends StatefulWidget {
  final AppState appState;
  final VoidCallback onOpenDrawer;

  const HomeScreenTab({
    super.key,
    required this.appState,
    required this.onOpenDrawer,
  });

  @override
  State<HomeScreenTab> createState() => _HomeScreenTabState();
}

class _HomeScreenTabState extends State<HomeScreenTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ReminderFilter _activeFilter = ReminderFilter.today;
  TimeSegment _activeSegment = TimeSegment.oneDay;
  QuickScheduleMode _activeQuickMode = QuickScheduleMode.none;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    EventService.instance.setSearchQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openAddReminder({
    String? initialTitle,
    DateTime? initialDate,
    TimeOfDay? initialTime,
    String? initialDescription,
  }) async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(
          initialTitle: initialTitle,
          initialDate: initialDate ?? DateTime.now(),
          initialTime: initialTime,
          initialDescription: initialDescription,
        ),
      ),
    );

    if (result == true) {
      await EventService.instance.loadEvents();
      if (mounted) setState(() {});
    }
  }

  void _openEventDetails(EventReminder event) async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(eventId: event.id),
      ),
    );
  }

  void _openEditReminder(EventReminder event) async {
    HapticFeedback.lightImpact();
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddEventScreen(existingEvent: event)),
    );
  }

  void _deleteReminder(EventReminder event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await EventService.instance.deleteEvent(event.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _moveToGoal(EventReminder event) {
    HapticFeedback.mediumImpact();
    widget.appState.moveEventToGoal(event);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${event.title}" to Goal Section! 🎯'),
        backgroundColor: AppTheme.primaryOrange,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VIEW GOALS',
          textColor: Colors.white,
          onPressed: () {
            widget.appState.setTabIndex(2);
          },
        ),
      ),
    );
  }

  List<EventReminder> _getFilteredEvents(EventService service) {
    if (_activeQuickMode != QuickScheduleMode.none) {
      switch (_activeQuickMode) {
        case QuickScheduleMode.sun:
          return service.earlyMorningEvents;
        case QuickScheduleMode.moon:
          return service.nightEvents;
        case QuickScheduleMode.coffee:
          return service.foodActivities;
        case QuickScheduleMode.study:
          return service.studyEvents;
        case QuickScheduleMode.evening:
          return service.eveningEvents;
        case QuickScheduleMode.nextWeek:
          return service.futureEvents;
        case QuickScheduleMode.none:
          break;
      }
    }

    List<EventReminder> baseList;

    if (_activeSegment == TimeSegment.oneDay) {
      // One Day: that day's daily activities AND study activities!
      baseList = service.todayAllActivities;
      if (_activeFilter == ReminderFilter.completed) {
        baseList = baseList.where((e) => e.isCompleted).toList();
      } else if (_activeFilter == ReminderFilter.overdue) {
        baseList = baseList.where((e) => e.isOverdue).toList();
      }
    } else if (_activeSegment == TimeSegment.oneMonth) {
      // One Month: display all monthly activities!
      baseList = service.currentMonthActivities;
      if (_activeFilter == ReminderFilter.completed) {
        baseList = baseList.where((e) => e.isCompleted).toList();
      } else if (_activeFilter == ReminderFilter.overdue) {
        baseList = baseList.where((e) => e.isOverdue).toList();
      }
    } else if (_activeSegment == TimeSegment.onTime) {
      // On Time: display daily activities only!
      baseList = service.onTimeDailyActivities;
    } else {
      switch (_activeFilter) {
        case ReminderFilter.today:
          baseList = service.todayEvents;
          break;
        case ReminderFilter.upcoming:
          baseList = service.upcomingEvents;
          break;
        case ReminderFilter.completed:
          baseList = service.completedEvents;
          break;
        case ReminderFilter.overdue:
          baseList = service.overdueEvents;
          break;
        case ReminderFilter.all:
          baseList = service.events;
          break;
      }
    }

    return baseList;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;

    return ListenableBuilder(
      listenable: EventService.instance,
      builder: (context, _) {
        final eventService = EventService.instance;
        final filteredEvents = _getFilteredEvents(eventService);
        final overdueCount = eventService.overdueEvents.length;

        return Scaffold(
          backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgCream,
          body: Stack(
            children: [
              // Background decorative leaf in bottom-left
              Positioned(
                left: -10,
                bottom: 40,
                child: BotanicalLeafSprig(
                  size: 110,
                  angle: 0.3,
                  color: isDark
                      ? const Color(0xFF5A4D40).withValues(alpha: 0.3)
                      : const Color(0xFFDCC8B3).withValues(alpha: 0.4),
                ),
              ),
              // Background decorative leaf in bottom-right
              Positioned(
                right: -10,
                bottom: 60,
                child: BotanicalLeafSprig(
                  size: 100,
                  angle: -0.4,
                  color: isDark
                      ? const Color(0xFF5A4D40).withValues(alpha: 0.3)
                      : const Color(0xFFDCC8B3).withValues(alpha: 0.4),
                ),
              ),

              SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 750),
                    child: RefreshIndicator(
                      color: AppTheme.primaryOrange,
                      onRefresh: () async {
                        await EventService.instance.syncWithSupabase();
                        await widget.appState.syncGoalsWithSupabase();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                      // 1. Top Header with Menu, Date / Branding, and Notification Bell
                      _buildTopHeader(context, isDark),

                      const SizedBox(height: 6),

                      // 1b. Home Motivational Banner (Banner image replacing Ready to Race, matching Calendar & Goals)
                      _buildHomeBanner(isDark),

                      const SizedBox(height: 14),

                      // 2. Segmented Time Bar: [One Day] [One Week] [On Time]
                      _buildSegmentedTimeBar(isDark),

                      const SizedBox(height: 16),

                      // 3. 8 Quick Action Buttons (2 Rows of 4 Circular Peach Icons)
                      _buildQuickActionGrid(context, isDark),

                      // 3b. Active Schedule Category Banner & Meal Quick Actions
                      _buildActiveQuickModeBanner(isDark),

                      const SizedBox(height: 18),

                      // 4. "My Moments" Section (Upload progress photos, asymmetric collage, add/view)
                      MyMomentsSection(isDark: isDark),

                      const SizedBox(height: 22),

                      // 6. "My Progress" Section (Consistency Bar Chart + Circular Ring Gauge)
                      MyProgressSection(isDark: isDark),

                      const SizedBox(height: 22),

                      // 7. Search Bar
                      _buildSearchBar(isDark),

                      const SizedBox(height: 12),

                      // 8. Filter Pills: [All] [Today] [Upcoming] [Completed] [Overdue]
                      _buildFilterPills(isDark, overdueCount),

                      const SizedBox(height: 16),

                      // 9. Overdue Alert Banner if any
                      if (overdueCount > 0 && _activeFilter != ReminderFilter.overdue)
                        _buildOverdueBanner(context, isDark, overdueCount),

                      // 10. Reminders Section Header & List
                      _buildRemindersSectionHeader(context, isDark, filteredEvents.length),

                      const SizedBox(height: 10),

                      // 11. Reminders List or Empty State
                      if (filteredEvents.isEmpty)
                        _buildEmptyState(isDark)
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Column(
                            children: filteredEvents.map((event) {
                              return EventCard(
                                event: event,
                                isDark: isDark,
                                onTap: () => _openEventDetails(event),
                                onToggleComplete: () => eventService.toggleComplete(event.id),
                                onEdit: () => _openEditReminder(event),
                                onDelete: () => _deleteReminder(event),
                                onMoveToGoal: () => _moveToGoal(event),
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ),
        ],
      ),

          // Floating Action Button with doodle text and arrow: "Create a Schedule"
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create a\nSchedule',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.caveat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: isDark ? const Color(0xFFE5B58F) : const Color(0xFF865538),
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const HandDrawnSwirlArrow(size: 22),
                  ],
                ),
              ),
              FloatingActionButton(
                heroTag: 'home_screen_fab',
                backgroundColor: AppTheme.primaryOrange,
                elevation: 6,
                shape: const CircleBorder(),
                tooltip: 'Create a Schedule',
                onPressed: () => _openAddReminder(),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final dayStr = DateFormat('dd').format(now);
    final monthStr = DateFormat('MMM').format(now);

    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18, top: 4, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Hamburger Menu
          GestureDetector(
            onTap: widget.onOpenDrawer,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF28221D).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                boxShadow: AppTheme.softShadow(isDark),
              ),
              child: Icon(
                Icons.menu_rounded,
                color: isDark ? AppTheme.textDarkPrimary : const Color(0xFF2C221B),
                size: 22,
              ),
            ),
          ),

          // Center Branding / Date
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/tarc_logo.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'TARC',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white : const Color(0xFF2E2018),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$dayStr $monthStr',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ),

          // Right Notification Bell
          GestureDetector(
            onTap: () => InteractiveModals.showNotificationsSheet(context, widget.appState),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF28221D).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                boxShadow: AppTheme.softShadow(isDark),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.primaryOrange,
                    size: 22,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5572E),
                        shape: BoxShape.circle,
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

  Widget _buildHomeBanner(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discipline today builds the freedom you want tomorrow! ✨'),
            backgroundColor: AppTheme.primaryOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow(isDark),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/images/home_banner.jpg',
            width: double.infinity,
            height: 140,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF6ED),
                      Color(0xFFFFDFBA),
                      Color(0xFFFFB37E),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedTimeBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : const Color(0xFFF0E5D8),
          width: 1,
        ),
        boxShadow: AppTheme.softShadow(),
      ),
      child: Row(
        children: [
          _buildSegmentItem(TimeSegment.oneDay, 'One Day', Icons.calendar_today_rounded, isDark),
          _buildSegmentItem(TimeSegment.oneMonth, 'One Month', Icons.calendar_month_rounded, isDark),
          _buildSegmentItem(TimeSegment.onTime, 'On Time', Icons.access_time_rounded, isDark),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(TimeSegment segment, String label, IconData icon, bool isDark) {
    final isSelected = _activeSegment == segment && _activeQuickMode == QuickScheduleMode.none;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _activeSegment = segment;
            _activeQuickMode = QuickScheduleMode.none;
            if (segment == TimeSegment.oneDay) {
              _activeFilter = ReminderFilter.today;
            } else if (segment == TimeSegment.onTime) {
              _activeFilter = ReminderFilter.upcoming;
            } else {
              _activeFilter = ReminderFilter.all;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : (isDark ? const Color(0xFFC7B7A9) : const Color(0xFF6B584B)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? const Color(0xFFC7B7A9) : const Color(0xFF6B584B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionGrid(BuildContext context, bool isDark) {
    final row1 = [
      {'name': 'Sun', 'mode': QuickScheduleMode.sun, 'icon': Icons.wb_sunny_rounded, 'color': AppTheme.primaryOrange},
      {'name': 'Moon', 'mode': QuickScheduleMode.moon, 'icon': Icons.nightlight_round, 'color': const Color(0xFF6B4EE6)},
      {'name': 'Coffee', 'mode': QuickScheduleMode.coffee, 'icon': Icons.coffee_rounded, 'color': const Color(0xFF8B4513)},
      {'name': 'Study', 'mode': QuickScheduleMode.study, 'icon': Icons.menu_book_rounded, 'color': const Color(0xFF1E88E5)},
    ];

    final row2 = [
      {'name': 'Evening', 'mode': QuickScheduleMode.evening, 'icon': Icons.wb_twilight_rounded, 'color': const Color(0xFFE5572E)},
      {'name': 'Next Week', 'mode': QuickScheduleMode.nextWeek, 'icon': Icons.calendar_month_outlined, 'color': const Color(0xFF2E7D32)},
      {'name': 'Custom', 'mode': QuickScheduleMode.none, 'icon': Icons.add_circle_outline_rounded, 'color': const Color(0xFF2C221B)},
      {'name': 'More', 'mode': QuickScheduleMode.none, 'icon': Icons.more_horiz_rounded, 'color': const Color(0xFF2C221B)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: row1.map((item) => _buildQuickActionButton(context, item, isDark)).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: row2.map((item) => _buildQuickActionButton(context, item, isDark)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(BuildContext context, Map<String, dynamic> item, bool isDark) {
    final name = item['name'] as String;
    final mode = item['mode'] as QuickScheduleMode;
    final icon = item['icon'] as IconData;
    final color = item['color'] as Color;
    final isSelected = mode != QuickScheduleMode.none && _activeQuickMode == mode;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (_searchController.text.isNotEmpty) {
          _searchController.clear();
        }
        if (mode != QuickScheduleMode.none) {
          setState(() {
            _activeQuickMode = _activeQuickMode == mode ? QuickScheduleMode.none : mode;
          });
        } else if (name == 'Custom') {
          _openAddReminder();
        } else {
          InteractiveModals.showNotificationsSheet(context, widget.appState);
        }
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryOrange
                  : (isDark ? const Color(0xFF38261A) : const Color(0xFFFFEDE0)),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF4A3425) : const Color(0xFFFCE1CE)),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppTheme.primaryOrange.withValues(alpha: 0.45)
                      : (isDark ? Colors.black26 : const Color(0xFFDCC8B8).withValues(alpha: 0.2)),
                  blurRadius: isSelected ? 10 : 6,
                  offset: isSelected ? const Offset(0, 3) : const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: isSelected
                  ? Colors.white
                  : (isDark && color == const Color(0xFF2C221B) ? Colors.white : color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppTheme.primaryOrange : AppTheme.text(isDark),
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppTheme.primaryOrange,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveQuickModeBanner(bool isDark) {
    if (_activeQuickMode == QuickScheduleMode.none) return const SizedBox.shrink();

    String title;
    String subtitle;
    IconData icon;
    Color iconColor;

    switch (_activeQuickMode) {
      case QuickScheduleMode.sun:
        title = "Early Morning Schedule";
        subtitle = "Morning routines & activities (5:00 AM – 12:00 PM)";
        icon = Icons.wb_sunny_rounded;
        iconColor = AppTheme.primaryOrange;
        break;
      case QuickScheduleMode.moon:
        title = "Night Schedule & Activities";
        subtitle = "Evening wind-down, reflection & bedtime (8:00 PM onwards)";
        icon = Icons.nightlight_round;
        iconColor = const Color(0xFF6B4EE6);
        break;
      case QuickScheduleMode.coffee:
        title = "Food & Meal Schedule";
        subtitle = "Coffee breaks, breakfast, lunch, snacks & nutrition";
        icon = Icons.coffee_rounded;
        iconColor = const Color(0xFF8B4513);
        break;
      case QuickScheduleMode.study:
        title = "Today's Study Schedule";
        subtitle = "Classes, lectures, reading blocks & study revision";
        icon = Icons.menu_book_rounded;
        iconColor = const Color(0xFF1E88E5);
        break;
      case QuickScheduleMode.evening:
        title = "Evening Schedule";
        subtitle = "Late afternoon & evening routine (4:00 PM – 8:00 PM)";
        icon = Icons.wb_twilight_rounded;
        iconColor = const Color(0xFFE5572E);
        break;
      case QuickScheduleMode.nextWeek:
        title = "Future Schedule";
        subtitle = "Next week & upcoming future schedules";
        icon = Icons.calendar_month_outlined;
        iconColor = const Color(0xFF2E7D32);
        break;
      case QuickScheduleMode.none:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 18, right: 18, top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF4A3425) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.text(isDark),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSub(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _activeQuickMode = QuickScheduleMode.none);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close_rounded, size: 14, color: AppTheme.text(isDark)),
                      const SizedBox(width: 4),
                      Text(
                        'Show All',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.text(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_activeQuickMode == QuickScheduleMode.coffee) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildMealChip('☕ Morning Coffee', const TimeOfDay(hour: 7, minute: 30), isDark),
                  _buildMealChip('🍳 Breakfast', const TimeOfDay(hour: 8, minute: 30), isDark),
                  _buildMealChip('🥗 Lunch Time', const TimeOfDay(hour: 13, minute: 0), isDark),
                  _buildMealChip('🍪 Evening Snacks', const TimeOfDay(hour: 16, minute: 30), isDark),
                  _buildMealChip('🍽️ Dinner Time', const TimeOfDay(hour: 20, minute: 0), isDark),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealChip(String title, TimeOfDay time, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _openAddReminder(
            initialTitle: title,
            initialTime: time,
            initialDate: DateTime.now(),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C221B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryOrange.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text(isDark),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.add_circle_outline_rounded, size: 14, color: AppTheme.primaryOrange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow(),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: AppTheme.text(isDark)),
        decoration: InputDecoration(
          hintText: 'Search reminders and tasks...',
          hintStyle: TextStyle(
            color: isDark ? AppTheme.textDarkSecondary : const Color(0xFF9E8E80),
            fontSize: 13.5,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryOrange, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterPills(bool isDark, int overdueCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip(ReminderFilter.all, 'All', isDark),
            const SizedBox(width: 8),
            _buildFilterChip(ReminderFilter.today, 'Today', isDark),
            const SizedBox(width: 8),
            _buildFilterChip(ReminderFilter.upcoming, 'Upcoming', isDark),
            const SizedBox(width: 8),
            _buildFilterChip(ReminderFilter.completed, 'Completed', isDark),
            const SizedBox(width: 8),
            _buildFilterChip(
              ReminderFilter.overdue,
              overdueCount > 0 ? 'Overdue ($overdueCount)' : 'Overdue',
              isDark,
              isAlert: overdueCount > 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(ReminderFilter filter, String label, bool isDark, {bool isAlert = false}) {
    final isSelected = _activeQuickMode == QuickScheduleMode.none && _activeFilter == filter;
    Color activeBg = AppTheme.primaryOrange;
    if (isAlert) activeBg = Colors.red.shade700;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _activeFilter = filter;
          _activeQuickMode = QuickScheduleMode.none;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeBg
              : (isDark ? AppTheme.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeBg
                : (isAlert ? Colors.red.withValues(alpha: 0.5) : (isDark ? AppTheme.borderDark : const Color(0xFFEADBCE))),
            width: isAlert ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBg.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isAlert ? Colors.red : AppTheme.text(isDark)),
          ),
        ),
      ),
    );
  }

  Widget _buildOverdueBanner(BuildContext context, bool isDark, int count) {
    return GestureDetector(
      onTap: () {
        setState(() => _activeFilter = ReminderFilter.overdue);
      },
      child: Container(
        margin: const EdgeInsets.only(left: 18, right: 18, bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You have $count overdue reminder${count > 1 ? 's' : ''} requiring attention.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.red, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersSectionHeader(BuildContext context, bool isDark, int count) {
    String title;
    IconData icon = Icons.event_note_rounded;

    if (_activeQuickMode != QuickScheduleMode.none) {
      switch (_activeQuickMode) {
        case QuickScheduleMode.sun:
          title = "Early Morning Schedule";
          icon = Icons.wb_sunny_rounded;
          break;
        case QuickScheduleMode.moon:
          title = "Night Schedule & Activities";
          icon = Icons.nightlight_round;
          break;
        case QuickScheduleMode.coffee:
          title = "Food & Meal Schedule";
          icon = Icons.coffee_rounded;
          break;
        case QuickScheduleMode.study:
          title = "Today's Study Schedule";
          icon = Icons.menu_book_rounded;
          break;
        case QuickScheduleMode.evening:
          title = "Evening Schedule";
          icon = Icons.wb_twilight_rounded;
          break;
        case QuickScheduleMode.nextWeek:
          title = "Future Schedule";
          icon = Icons.calendar_month_outlined;
          break;
        case QuickScheduleMode.none:
          title = "Today's Reminders";
          break;
      }
    } else {
      if (_activeSegment == TimeSegment.oneDay) {
        title = "Today's Daily & Study Activities";
        icon = Icons.today_rounded;
      } else if (_activeSegment == TimeSegment.oneMonth) {
        title = "Monthly Activities";
        icon = Icons.calendar_month_rounded;
      } else if (_activeSegment == TimeSegment.onTime) {
        title = "Daily Activities Only (On Time)";
        icon = Icons.access_time_filled_rounded;
      } else {
        switch (_activeFilter) {
          case ReminderFilter.today:
            title = "Today's Reminders";
            break;
          case ReminderFilter.upcoming:
            title = 'Upcoming Reminders';
            break;
          case ReminderFilter.completed:
            title = 'Completed Tasks';
            break;
          case ReminderFilter.overdue:
            title = 'Overdue Reminders';
            break;
          case ReminderFilter.all:
            title = 'All Reminders';
            break;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryOrange),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.text(isDark),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              if (_activeQuickMode != QuickScheduleMode.none)
                TextButton(
                  onPressed: () => setState(() => _activeQuickMode = QuickScheduleMode.none),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSub(isDark),
                    ),
                  ),
                ),
              TextButton(
                onPressed: () {
                  String? initialTitle;
                  TimeOfDay? initialTime;
                  DateTime? initialDate;
                  if (_activeQuickMode == QuickScheduleMode.sun) {
                    initialTitle = 'Morning Routine';
                    initialTime = const TimeOfDay(hour: 7, minute: 0);
                  } else if (_activeQuickMode == QuickScheduleMode.moon) {
                    initialTitle = 'Night Reflection';
                    initialTime = const TimeOfDay(hour: 21, minute: 30);
                  } else if (_activeQuickMode == QuickScheduleMode.coffee) {
                    initialTitle = 'Coffee & Snack Time';
                    initialTime = const TimeOfDay(hour: 16, minute: 30);
                  } else if (_activeQuickMode == QuickScheduleMode.study) {
                    initialTitle = 'Study Block';
                    initialTime = const TimeOfDay(hour: 10, minute: 0);
                  } else if (_activeQuickMode == QuickScheduleMode.evening) {
                    initialTitle = 'Evening Routine / Exercise';
                    initialTime = const TimeOfDay(hour: 17, minute: 30);
                  } else if (_activeQuickMode == QuickScheduleMode.nextWeek) {
                    initialDate = DateTime.now().add(const Duration(days: 7));
                  }
                  _openAddReminder(
                    initialTitle: initialTitle,
                    initialTime: initialTime,
                    initialDate: initialDate,
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 16, color: AppTheme.primaryOrange),
                    const SizedBox(width: 2),
                    Text(
                      'Add',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    // 1. Next Week / Future Schedule Empty State with the user's exact required message
    if (_activeQuickMode == QuickScheduleMode.nextWeek) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        padding: const EdgeInsets.all(26),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppTheme.primaryOrange.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryOrange.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded, size: 36, color: AppTheme.primaryOrange),
            ),
            const SizedBox(height: 14),
            Text(
              'think fastly update me as soon as possible',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryOrange,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No future schedule scheduled for next week! Add your upcoming goals, study sessions, and events right now.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppTheme.textSub(isDark),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              label: Text(
                'Plan Next Week Schedule',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              onPressed: () => _openAddReminder(
                initialDate: DateTime.now().add(const Duration(days: 7)),
                initialTitle: 'Next Week Goal',
              ),
            ),
          ],
        ),
      );
    }

    // 2. Coffee / Food Empty State with quick meal templates
    if (_activeQuickMode == QuickScheduleMode.coffee) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppTheme.borderDark : const Color(0xFFEADBCE),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.coffee_rounded, size: 36, color: AppTheme.primaryOrange),
            ),
            const SizedBox(height: 14),
            Text(
              'No food & meal activities scheduled',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.text(isDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Track your breakfast, coffee time, lunch, and evening snacks to keep your energy high!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppTheme.textSub(isDark),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildMealChip('☕ Morning Coffee', const TimeOfDay(hour: 7, minute: 30), isDark),
                _buildMealChip('🍳 Breakfast', const TimeOfDay(hour: 8, minute: 30), isDark),
                _buildMealChip('🥗 Lunch Time', const TimeOfDay(hour: 13, minute: 0), isDark),
                _buildMealChip('🍪 Evening Snacks', const TimeOfDay(hour: 16, minute: 30), isDark),
                _buildMealChip('🍽️ Dinner Time', const TimeOfDay(hour: 20, minute: 0), isDark),
              ],
            ),
          ],
        ),
      );
    }

    // 3. Sun (Early Morning) Empty State
    if (_activeQuickMode == QuickScheduleMode.sun) {
      return _buildQuickModeEmptyCard(
        isDark: isDark,
        icon: Icons.wb_sunny_rounded,
        title: 'No early morning schedule found',
        description: 'Plan your morning routine (5 AM – 12 PM) to start your day energized and focused.',
        buttonLabel: 'Add Morning Routine',
        onAdd: () => _openAddReminder(
          initialTitle: 'Morning Routine',
          initialTime: const TimeOfDay(hour: 7, minute: 0),
        ),
      );
    }

    // 4. Moon (Night) Empty State
    if (_activeQuickMode == QuickScheduleMode.moon) {
      return _buildQuickModeEmptyCard(
        isDark: isDark,
        icon: Icons.nightlight_round,
        title: 'No night schedule found',
        description: 'Plan your evening wind-down, daily reflection, or bedtime routine (after 8 PM).',
        buttonLabel: 'Add Night Routine',
        onAdd: () => _openAddReminder(
          initialTitle: 'Night Reflection & Sleep',
          initialTime: const TimeOfDay(hour: 21, minute: 30),
        ),
      );
    }

    // 5. Study Empty State
    if (_activeQuickMode == QuickScheduleMode.study) {
      return _buildQuickModeEmptyCard(
        isDark: isDark,
        icon: Icons.menu_book_rounded,
        title: 'No study schedule for today',
        description: 'Schedule your classes, reading goals, assignments, or revision sessions.',
        buttonLabel: 'Add Study Schedule',
        onAdd: () => _openAddReminder(
          initialTitle: 'Study & Revision Session',
          initialTime: const TimeOfDay(hour: 10, minute: 0),
        ),
      );
    }

    // 6. Evening Empty State
    if (_activeQuickMode == QuickScheduleMode.evening) {
      return _buildQuickModeEmptyCard(
        isDark: isDark,
        icon: Icons.wb_twilight_rounded,
        title: 'No evening schedule found',
        description: 'Schedule your late afternoon or evening routine, exercise, or relaxation (4 PM – 8 PM).',
        buttonLabel: 'Add Evening Activity',
        onAdd: () => _openAddReminder(
          initialTitle: 'Evening Exercise / Routine',
          initialTime: const TimeOfDay(hour: 17, minute: 30),
        ),
      );
    }

    // Standard Empty State
    final isToday = _activeFilter == ReminderFilter.today || _activeSegment == TimeSegment.oneDay;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      padding: const EdgeInsets.all(28),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : const Color(0xFFEADBCE),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alarm_on_rounded, size: 36, color: AppTheme.primaryOrange),
          ),
          const SizedBox(height: 14),
          Text(
            isToday ? 'No reminders for today' : 'No reminders found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.text(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isToday
                ? 'You are all caught up for today! Add a reminder or schedule to stay productive.'
                : 'Keep your schedule on track by adding your first reminder.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppTheme.textSub(isDark),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            label: Text(
              isToday ? 'Create Today\'s Reminder' : 'Create Reminder',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            onPressed: () => _openAddReminder(initialDate: DateTime.now()),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickModeEmptyCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onAdd,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      padding: const EdgeInsets.all(26),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : const Color(0xFFEADBCE),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: AppTheme.primaryOrange),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.text(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppTheme.textSub(isDark),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            label: Text(
              buttonLabel,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
