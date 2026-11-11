import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_time_utils.dart';
import 'add_event_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  EventReminder? _event;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  void _loadEvent() {
    setState(() => _loading = true);
    final event = EventService.instance.getEventById(widget.eventId);
    setState(() {
      _event = event;
      _loading = false;
    });
  }

  Future<void> _toggleComplete() async {
    if (_event == null) return;
    HapticFeedback.mediumImpact();
    await EventService.instance.toggleComplete(_event!.id);
    _loadEvent();
  }

  Future<void> _deleteEvent() async {
    if (_event == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: Text('Are you sure you want to delete "${_event!.title}"? This will also cancel any scheduled notifications.'),
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
      await EventService.instance.deleteEvent(_event!.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _editEvent() async {
    if (_event == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(existingEvent: _event),
      ),
    );

    if (updated == true) {
      _loadEvent();
    }
  }

  Future<void> _moveToGoal() async {
    if (_event == null) return;
    HapticFeedback.mediumImpact();
    final event = _event!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalsStr = prefs.getString('user_goals_data');
      List<dynamic> list = [];
      if (goalsStr != null) {
        try {
          list = jsonDecode(goalsStr) as List<dynamic>;
        } catch (_) {}
      }
      final newGoal = GoalItem(
        id: 'goal_from_${event.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: event.title,
        subtitle: event.description.isNotEmpty
            ? event.description
            : 'Scheduled: ${event.time} • ${event.repeatType}',
        progress: event.isCompleted ? 1.0 : 0.0,
        category: 'Schedule',
        fromSchedule: true,
      );
      list.insert(0, newGoal.toMap());
      await prefs.setString('user_goals_data', jsonEncode(list));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moved "${event.title}" to Goal Section! 🎯'),
            backgroundColor: AppTheme.primaryOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[EventDetailsScreen] Error moving to goal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgCream,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgCream,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppTheme.text(isDark)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded, size: 64, color: AppTheme.textSub(isDark)),
                const SizedBox(height: 16),
                Text(
                  'Event Not Found',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This reminder may have been deleted or no longer exists.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSub(isDark)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Reminders', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final event = _event!;
    final isOverdue = event.isOverdue;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.text(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reminder Details',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.text(isDark),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            tooltip: 'Edit Reminder',
            onPressed: _editEvent,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: 'Delete Reminder',
            onPressed: _deleteEvent,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.softShadow(isDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Completion button
                        GestureDetector(
                          onTap: _toggleComplete,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: event.isCompleted
                                  ? Colors.green
                                  : (isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0)),
                              border: Border.all(
                                color: event.isCompleted
                                    ? Colors.green
                                    : (isOverdue ? Colors.red : AppTheme.primaryOrange),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              event.isCompleted ? Icons.check : null,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.text(isDark),
                                  decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: event.isCompleted
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : (isOverdue
                                              ? Colors.red.withValues(alpha: 0.15)
                                              : AppTheme.primaryOrange.withValues(alpha: 0.15)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      event.isCompleted
                                          ? 'COMPLETED'
                                          : (isOverdue ? 'OVERDUE' : 'SCHEDULED'),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: event.isCompleted
                                            ? Colors.green
                                            : (isOverdue ? Colors.red : AppTheme.primaryOrange),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2E241E) : const Color(0xFFF0EBE5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${event.priority.toUpperCase()} PRIORITY',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.text(isDark),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Description',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSub(isDark),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.description,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.4,
                          color: AppTheme.text(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Scheduling Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.softShadow(isDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timing & Frequency',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text(isDark),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildDetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: DateTimeUtils.formatDate(event.date),
                      isDark: isDark,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Time',
                      value: event.time,
                      isDark: isDark,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      icon: Icons.alarm_rounded,
                      label: 'Reminder',
                      value: DateTimeUtils.formatDateTime(event.reminderDateTime),
                      isDark: isDark,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      icon: Icons.repeat_rounded,
                      label: 'Repeat',
                      value: event.repeatTypeEnum == RepeatType.custom
                          ? 'Every ${event.repeatInterval} days'
                          : event.repeatType,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(
                          color: event.isCompleted ? Colors.orange : Colors.green,
                        ),
                      ),
                      icon: Icon(
                        event.isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded,
                        color: event.isCompleted ? Colors.orange : Colors.green,
                      ),
                      label: Text(
                        event.isCompleted ? 'Mark Incomplete' : 'Mark Completed',
                        style: TextStyle(
                          color: event.isCompleted ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: _toggleComplete,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      label: const Text(
                        'Edit',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      onPressed: _editEvent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                    foregroundColor: AppTheme.primaryOrange,
                    elevation: 0,
                    side: const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.track_changes_rounded, color: AppTheme.primaryOrange),
                  label: const Text(
                    'Move to Goal Section 🎯',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  onPressed: _moveToGoal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2E241E) : const Color(0xFFFFEDE0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryOrange),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppTheme.textSub(isDark),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.text(isDark),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
