import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_time_utils.dart';

class AddEventScreen extends StatefulWidget {
  final EventReminder? existingEvent; // If provided with valid id, mode is EDIT
  final String? initialTitle;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final String? initialDescription;

  const AddEventScreen({
    super.key,
    this.existingEvent,
    this.initialTitle,
    this.initialDate,
    this.initialTime,
    this.initialDescription,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customIntervalController = TextEditingController(text: '1');

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late RepeatType _repeatType;
  late String _priority;

  bool _isSaving = false;
  String? _pastTimeWarning;

  bool get isEditMode => widget.existingEvent != null && widget.existingEvent!.id.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;
    if (existing != null && existing.id.trim().isNotEmpty) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _selectedDate = existing.date;
      _selectedTime = DateTimeUtils.parseTimeOfDay(existing.time);
      _repeatType = existing.repeatTypeEnum;
      _customIntervalController.text = existing.repeatInterval.toString();
      _priority = existing.priority;
    } else {
      final now = DateTime.now();
      _selectedDate = widget.initialDate ?? (existing != null ? existing.date : DateTime(now.year, now.month, now.day));
      _titleController.text = widget.initialTitle ?? (existing != null ? existing.title : '');
      _descriptionController.text = widget.initialDescription ?? (existing != null ? existing.description : '');
      if (widget.initialTime != null) {
        _selectedTime = widget.initialTime!;
      } else if (existing != null && existing.time.isNotEmpty) {
        _selectedTime = DateTimeUtils.parseTimeOfDay(existing.time);
      } else {
        final nextTime = now.add(const Duration(minutes: 15));
        _selectedTime = TimeOfDay(hour: nextTime.hour, minute: nextTime.minute);
      }
      _repeatType = existing != null ? existing.repeatTypeEnum : RepeatType.none;
      _priority = existing != null ? existing.priority : 'medium';
    }

    _checkPastTime();
  }

  void _checkPastTime() {
    final combined = DateTimeUtils.combineDateAndTime(_selectedDate, _selectedTime);

    if (_repeatType == RepeatType.none && combined.isBefore(DateTime.now())) {
      setState(() {
        _pastTimeWarning = 'Notice: The selected time is in the past. If saved, notification will not trigger unless set to repeat.';
      });
    } else {
      setState(() {
        _pastTimeWarning = null;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customIntervalController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryOrange,
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C221B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _checkPastTime();
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryOrange,
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C221B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _checkPastTime();
      });
    }
  }

  Future<void> _saveReminder() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for the reminder'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final timeString = DateTimeUtils.formatTimeOfDay(_selectedTime);
      final reminderTime = DateTimeUtils.combineDateAndTime(_selectedDate, _selectedTime);
      final interval = int.tryParse(_customIntervalController.text.trim()) ?? 1;

      final now = DateTime.now();

      if (isEditMode) {
        final existing = widget.existingEvent!;
        final updatedEvent = existing.copyWith(
          title: title,
          description: _descriptionController.text.trim(),
          date: _selectedDate,
          time: timeString,
          reminderDateTime: reminderTime,
          repeatType: _repeatType.label,
          repeatInterval: interval,
          priority: _priority,
          updatedAt: now,
        );

        final success = await EventService.instance.updateEvent(updatedEvent);
        if (mounted) {
          setState(() => _isSaving = false);
          if (success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reminder updated for $timeString!'),
                backgroundColor: AppTheme.primaryOrange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update reminder. Please try again.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        // Prevent accidental identical duplicates scheduled within 5 seconds
        final notificationId = DateTimeUtils.generateNotificationId();
        final newEvent = EventReminder(
          id: const Uuid().v4(),
          title: title,
          description: _descriptionController.text.trim(),
          date: _selectedDate,
          time: timeString,
          reminderDateTime: reminderTime,
          repeatType: _repeatType.label,
          repeatInterval: interval,
          isCompleted: false,
          notificationId: notificationId,
          createdAt: now,
          updatedAt: now,
          priority: _priority,
        );

        final success = await EventService.instance.addEvent(newEvent);
        if (mounted) {
          setState(() => _isSaving = false);
          if (success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reminder "$title" scheduled for $timeString!'),
                backgroundColor: AppTheme.primaryOrange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to schedule reminder. Please try again.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          isEditMode ? 'Edit Reminder' : 'New Reminder',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.text(isDark),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: TextButton(
              onPressed: _isSaving ? null : _saveReminder,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryOrange),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Past warning alert if any
                if (_pastTimeWarning != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade700, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _pastTimeWarning!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title Input
                Text(
                  'Title *',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSub(isDark),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  autofocus: !isEditMode,
                  style: TextStyle(color: AppTheme.text(isDark), fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'e.g. Study Quantitative Aptitude, Team Meeting',
                    hintStyle: TextStyle(color: isDark ? const Color(0xFF6B5E52) : const Color(0xFFA89A8E)),
                    filled: true,
                    fillColor: isDark ? AppTheme.cardDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Description Input
                Text(
                  'Description (Optional)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSub(isDark),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: TextStyle(color: AppTheme.text(isDark), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add notes, checklist or location...',
                    hintStyle: TextStyle(color: isDark ? const Color(0xFF6B5E52) : const Color(0xFFA89A8E)),
                    filled: true,
                    fillColor: isDark ? AppTheme.cardDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 20),

                // Date & Time Selectors Row
                Row(
                  children: [
                    // Date Card
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppTheme.borderDark : const Color(0xFFEADBCE),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryOrange),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Date',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSub(isDark),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateTimeUtils.formatDate(_selectedDate),
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.text(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Time Card
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppTheme.borderDark : const Color(0xFFEADBCE),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.primaryOrange),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Time',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSub(isDark),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateTimeUtils.formatTimeOfDay(_selectedTime),
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.text(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Repeat Type Selector
                Text(
                  'Repeat Interval',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSub(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RepeatType.values.map((type) {
                    final isSelected = _repeatType == type;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _repeatType = type;
                          _checkPastTime();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryOrange
                              : (isDark ? AppTheme.cardDark : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryOrange
                                : (isDark ? AppTheme.borderDark : const Color(0xFFEADBCE)),
                          ),
                        ),
                        child: Text(
                          type.label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppTheme.text(isDark),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Custom Interval Input if Custom is selected
                if (_repeatType == RepeatType.custom) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Every',
                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.text(isDark)),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          controller: _customIntervalController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.text(isDark), fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? AppTheme.cardDark : Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'days',
                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.text(isDark)),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Priority Selector
                Text(
                  'Priority',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSub(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPriorityOption('low', 'Low', Colors.green, isDark),
                    const SizedBox(width: 10),
                    _buildPriorityOption('medium', 'Medium', Colors.blue, isDark),
                    const SizedBox(width: 10),
                    _buildPriorityOption('high', 'High', Colors.red, isDark),
                  ],
                ),

                const SizedBox(height: 32),

                // Big Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveReminder,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isEditMode ? 'Update Reminder' : 'Set Reminder',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityOption(String key, String label, Color color, bool isDark) {
    final isSelected = _priority.toLowerCase() == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _priority = key);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.18)
                : (isDark ? AppTheme.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : (isDark ? AppTheme.borderDark : const Color(0xFFEADBCE)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppTheme.text(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
