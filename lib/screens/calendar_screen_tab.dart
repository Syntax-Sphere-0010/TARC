import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/app_state.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_time_utils.dart';
import '../widgets/event_card.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/scenic_illustrations.dart';
import '../widgets/interactive_modals.dart';
import 'add_event_screen.dart';
import 'event_details_screen.dart';

class CalendarScreenTab extends StatefulWidget {
  final AppState appState;
  final VoidCallback onOpenDrawer;

  const CalendarScreenTab({
    super.key,
    required this.appState,
    required this.onOpenDrawer,
  });

  @override
  State<CalendarScreenTab> createState() => _CalendarScreenTabState();
}

class _CalendarScreenTabState extends State<CalendarScreenTab> {
  DateTime _selectedDate = DateTime.now();
  int _calendarFilterMode = 0; // 0: One Day (Daily & Study), 1: One Month, 2: On Time (Daily only)

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    EventService.instance.setSelectedDate(date);
  }

  void _openAddReminder() async {
    HapticFeedback.mediumImpact();
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEventScreen()),
    );
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

  void _moveToGoal(EventReminder event) {
    HapticFeedback.mediumImpact();
    widget.appState.moveEventToGoal(event);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moved "${event.title}" to Goal Section! 🎯'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;

    return ListenableBuilder(
      listenable: EventService.instance,
      builder: (context, _) {
        final eventService = EventService.instance;
        final selectedDayEvents = eventService.getEventsForDate(_selectedDate);
        final daysWithEvents = eventService.getDaysWithEventsInMonth(_selectedDate);

        // Filter events according to user request:
        // 0: One Day -> that day's daily activities and study activities
        // 1: One Month -> all monthly activities
        // 2: On Time -> daily activities only (active)
        List<EventReminder> displayedEvents;
        String sectionTitle;
        if (_calendarFilterMode == 0) {
          displayedEvents = selectedDayEvents;
          sectionTitle = '${DateTimeUtils.getRelativeDay(_selectedDate)}: Daily & Study Activities';
        } else if (_calendarFilterMode == 1) {
          displayedEvents = eventService.events.where((e) {
            return (e.date.year == _selectedDate.year && e.date.month == _selectedDate.month) ||
                (e.reminderDateTime.year == _selectedDate.year && e.reminderDateTime.month == _selectedDate.month) ||
                e.repeatType.toLowerCase() == 'daily' ||
                e.repeatType.toLowerCase() == 'monthly';
          }).toList();
          sectionTitle = 'Monthly Activities (${DateTimeUtils.formatDate(_selectedDate).split(',')[0].trim()})';
        } else {
          displayedEvents = selectedDayEvents.where((e) => !eventService.isStudyEvent(e) || e.repeatType.toLowerCase() == 'daily').toList();
          if (displayedEvents.isEmpty) {
            displayedEvents = eventService.onTimeDailyActivities;
          }
          sectionTitle = 'Daily Activities Only (On Time)';
        }

        return Scaffold(
          backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgCream,
          body: Stack(
            children: [
              // Botanical leaf in top right corner
              Positioned(
                right: -6,
                top: 10,
                child: BotanicalLeafSprig(
                  size: 85,
                  angle: -0.6,
                  color: isDark ? const Color(0xFF5A4D40).withValues(alpha: 0.3) : null,
                ),
              ),
              // Botanical leaf in bottom left corner
              Positioned(
                left: -12,
                bottom: 40,
                child: BotanicalLeafSprig(
                  size: 90,
                  angle: 0.5,
                  color: isDark ? const Color(0xFF5A4D40).withValues(alpha: 0.3) : null,
                ),
              ),

              SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 750),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Top Header with Menu, MoveRemind & Date badge, and Notification Bell
                          _buildTopHeader(context, isDark),

                          const SizedBox(height: 6),

                          // 1b. Motivational Calendar Banner ("Trust Yourself. You Can Do This")
                          _buildCalendarBanner(isDark),

                          const SizedBox(height: 14),

                          // 2. Real Interactive Calendar Card with dynamic event dots
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: CalendarWidget(
                              selectedDate: _selectedDate,
                              daysWithEvents: daysWithEvents,
                              isDark: isDark,
                              onDateSelected: _onDateSelected,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 2b. View Mode Selector: [One Day] [One Month] [On Time]
                          _buildCalendarFilterBar(isDark),

                          const SizedBox(height: 16),

                          // 3. Section Header
                          _buildDateSectionHeader(context, isDark, sectionTitle, displayedEvents.length),

                          const SizedBox(height: 10),

                          // 4. Reminders List for Selected View
                          if (displayedEvents.isEmpty)
                            _buildEmptyDateState(isDark)
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: Column(
                                children: displayedEvents.map((event) {
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

                          const SizedBox(height: 24),

                          // 5. Upcoming Reminders Preview (Next 7 Days)
                          _buildUpcomingSection(context, isDark, eventService),

                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'calendar_screen_fab',
            backgroundColor: AppTheme.primaryOrange,
            elevation: 4,
            tooltip: 'Add Reminder',
            onPressed: _openAddReminder,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        );
      },
    );
  }

  Widget _buildCalendarFilterBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : const Color(0xFFF0E5D8),
          width: 1,
        ),
        boxShadow: AppTheme.softShadow(isDark),
      ),
      child: Row(
        children: [
          _buildFilterChip(0, 'One Day', Icons.today_rounded, isDark),
          _buildFilterChip(1, 'One Month', Icons.calendar_month_rounded, isDark),
          _buildFilterChip(2, 'On Time', Icons.access_time_filled_rounded, isDark),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, IconData icon, bool isDark) {
    final isSelected = _calendarFilterMode == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _calendarFilterMode = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
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
                size: 14,
                color: isSelected ? Colors.white : (isDark ? const Color(0xFFC7B7A9) : const Color(0xFF6B584B)),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? const Color(0xFFD6C7BA) : const Color(0xFF554438)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final dayStr = DateFormat('dd').format(now);
    final monthStr = DateFormat('MMM').format(now);

    return Container(
      margin: const EdgeInsets.only(left: 18, right: 18, top: 8, bottom: 8),
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

          // Center Title + Date pill
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

  Widget _buildDateSectionHeader(BuildContext context, bool isDark, String title, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.event_available_rounded, size: 20, color: AppTheme.primaryOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
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
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryOrange),
            tooltip: 'Add Reminder',
            onPressed: _openAddReminder,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDateState(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow(isDark),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_note_outlined, size: 40, color: AppTheme.textSub(isDark)),
            const SizedBox(height: 8),
            Text(
              'No reminders for this selection',
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.text(isDark),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryOrange,
                side: const BorderSide(color: AppTheme.primaryOrange),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add reminder'),
              onPressed: _openAddReminder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(BuildContext context, bool isDark, EventService service) {
    final upcoming = service.upcomingEvents;
    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upcoming_rounded, size: 18, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              Text(
                'Upcoming Schedule',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: upcoming.take(5).map((event) {
              return EventCard(
                event: event,
                isDark: isDark,
                onTap: () => _openEventDetails(event),
                onToggleComplete: () => service.toggleComplete(event.id),
                onEdit: () => _openEditReminder(event),
                onDelete: () => _deleteReminder(event),
                onMoveToGoal: () => _moveToGoal(event),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarBanner(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trust yourself. You can do this! Keep moving forward ✨'),
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
            'assets/images/calendar_banner.jpg',
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
}
