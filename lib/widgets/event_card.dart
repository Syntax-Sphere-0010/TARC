import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import '../utils/date_time_utils.dart';

class EventCard extends StatelessWidget {
  final EventReminder event;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMoveToGoal;

  const EventCard({
    super.key,
    required this.event,
    required this.isDark,
    required this.onTap,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    this.onMoveToGoal,
  });

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    Color priorityBg;
    switch (event.priority.toLowerCase()) {
      case 'high':
        priorityColor = AppTheme.highBadgeText;
        priorityBg = isDark ? AppTheme.highBadgeBgDark : AppTheme.highBadgeBg;
        break;
      case 'low':
        priorityColor = AppTheme.lowBadgeText;
        priorityBg = isDark ? AppTheme.lowBadgeBgDark : AppTheme.lowBadgeBg;
        break;
      case 'medium':
      default:
        priorityColor = AppTheme.mediumBadgeText;
        priorityBg = isDark ? AppTheme.mediumBadgeBgDark : AppTheme.mediumBadgeBg;
        break;
    }

    final isOverdue = event.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isOverdue
            ? Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1.5)
            : (event.isCompleted
                ? Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1)
                : null),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFFDCC8B8).withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion Checkbox / Toggle
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onToggleComplete();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: event.isCompleted
                          ? Colors.green
                          : (isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0)),
                      border: Border.all(
                        color: event.isCompleted
                            ? Colors.green
                            : (isOverdue ? Colors.red : AppTheme.primaryOrange),
                        width: 1.8,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        event.isCompleted ? Icons.check : (isOverdue ? Icons.priority_high : null),
                        size: 16,
                        color: event.isCompleted ? Colors.white : (isOverdue ? Colors.red : Colors.transparent),
                      ),
                    ),
                  ),
                ),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Badges
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: event.isCompleted
                                    ? (isDark ? Colors.grey.shade500 : Colors.grey.shade400)
                                    : AppTheme.text(isDark),
                                decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          // Priority Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.priority.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (event.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSub(isDark),
                            decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Time, Date, Repeat, Overdue tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Time & Date
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: isOverdue ? Colors.red : AppTheme.textSub(isDark),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${DateTimeUtils.getRelativeDay(event.date)} at ${event.time}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isOverdue ? Colors.red : AppTheme.textSub(isDark),
                                ),
                              ),
                            ],
                          ),

                          // Repeat indicator
                          if (event.repeatTypeEnum != RepeatType.none)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2E241E) : const Color(0xFFFFF0E6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.repeat_rounded, size: 12, color: AppTheme.primaryOrange),
                                  const SizedBox(width: 3),
                                  Text(
                                    event.repeatType,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Overdue indicator
                          if (isOverdue)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'OVERDUE',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // "Move to Goal Section" Quick Button
                      if (onMoveToGoal != null)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onMoveToGoal!();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.primaryOrange.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.track_changes_rounded, size: 13, color: AppTheme.primaryOrange),
                                const SizedBox(width: 5),
                                Text(
                                  'Move to Goal Section',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.primaryOrange),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 3-dots Context Menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: isDark ? AppTheme.textDarkSecondary : const Color(0xFFB5A89B),
                  ),
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (value) {
                    if (value == 'toggle') {
                      onToggleComplete();
                    } else if (value == 'goal') {
                      onMoveToGoal?.call();
                    } else if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                          children: [
                            Icon(
                              event.isCompleted ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                              size: 18,
                              color: AppTheme.primaryOrange,
                            ),
                            const SizedBox(width: 8),
                            Text(event.isCompleted ? 'Mark Incomplete' : 'Mark Completed'),
                          ],
                        ),
                    ),
                    if (onMoveToGoal != null)
                      const PopupMenuItem(
                        value: 'goal',
                        child: Row(
                          children: [
                            Icon(Icons.track_changes_rounded, size: 18, color: AppTheme.primaryOrange),
                            SizedBox(width: 8),
                            Text('Move to Goal Section'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit Reminder'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
