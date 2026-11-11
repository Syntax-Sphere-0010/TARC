import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../database/database_helper.dart';
import '../utils/date_time_utils.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

class EventService extends ChangeNotifier {
  static final EventService instance = EventService._internal();
  EventService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final NotificationService _notifications = NotificationService.instance;
  final SupabaseService _supabase = SupabaseService.instance;

  List<EventReminder> _events = [];
  bool _isLoading = false;
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();

  List<EventReminder> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  DateTime get selectedDate => _selectedDate;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Initialize and load all events from database + reschedule active notifications
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await loadEvents();
    await rescheduleAllActive();

    // Background sync with Supabase if initialized
    if (_supabase.isInitialized) {
      syncWithSupabase().catchError((e) {
        debugPrint('[EventService] Background sync error: $e');
      });
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sync local SQLite events with Supabase
  Future<void> syncWithSupabase() async {
    if (!_supabase.isInitialized) return;
    try {
      final remoteEvents = await _supabase.fetchSchedules();
      if (remoteEvents.isNotEmpty) {
        for (final remote in remoteEvents) {
          await _db.insertEvent(remote);
        }
        await loadEvents();
      } else if (_events.isNotEmpty) {
        // Push local events to remote Supabase
        for (final local in _events) {
          await _supabase.saveSchedule(local);
        }
      }
    } catch (e) {
      debugPrint('[EventService] syncWithSupabase error: $e');
    }
  }

  /// Load all events from database
  Future<void> loadEvents() async {
    try {
      if (_searchQuery.trim().isEmpty) {
        _events = await _db.getAllEvents();
      } else {
        _events = await _db.searchEvents(_searchQuery);
      }
    } catch (e) {
      debugPrint('[EventService] Error loading events: $e');
      _events = [];
    }
    notifyListeners();
  }

  /// Add a new reminder event
  Future<bool> addEvent(EventReminder event) async {
    try {
      await _db.insertEvent(event);
      try {
        await _notifications.scheduleReminderNotification(event);
      } catch (notifErr) {
        debugPrint('[EventService] Non-critical notification schedule error: $notifErr');
      }
      await loadEvents();
      debugPrint('[EventService] Successfully created and saved event: ${event.title}');

      // Sync to Supabase
      if (_supabase.isInitialized) {
        _supabase.saveSchedule(event).catchError((e) {
          debugPrint('[EventService] Supabase add sync error: $e');
          return false;
        });
      }

      return true;
    } catch (e) {
      debugPrint('[EventService] Error adding event: $e');
      return false;
    }
  }

  /// Update an existing reminder event
  Future<bool> updateEvent(EventReminder updatedEvent) async {
    try {
      final oldEvent = await _db.getEventById(updatedEvent.id);
      if (oldEvent != null) {
        // Cancel old notification to guarantee no ghost alarms
        await _notifications.cancelNotification(oldEvent.notificationId);
      }

      await _db.updateEvent(updatedEvent);

      // Schedule new notification if active
      if (!updatedEvent.isCompleted) {
        await _notifications.scheduleReminderNotification(updatedEvent);
      }

      await loadEvents();
      debugPrint('[EventService] Successfully updated event: ${updatedEvent.title}');

      // Sync to Supabase
      if (_supabase.isInitialized) {
        _supabase.updateSchedule(updatedEvent).catchError((e) {
          debugPrint('[EventService] Supabase update sync error: $e');
          return false;
        });
      }

      return true;
    } catch (e) {
      debugPrint('[EventService] Error updating event: $e');
      return false;
    }
  }

  /// Delete an event and cancel its notification
  Future<bool> deleteEvent(String id) async {
    try {
      final event = await _db.getEventById(id);
      if (event != null) {
        await _notifications.cancelNotification(event.notificationId);
      }
      await _db.deleteEvent(id);
      await loadEvents();
      debugPrint('[EventService] Successfully deleted event: $id');

      // Sync to Supabase
      if (_supabase.isInitialized) {
        _supabase.deleteSchedule(id).catchError((e) {
          debugPrint('[EventService] Supabase delete sync error: $e');
          return false;
        });
      }

      return true;
    } catch (e) {
      debugPrint('[EventService] Error deleting event: $e');
      return false;
    }
  }

  /// Toggle completion status
  Future<bool> toggleComplete(String id) async {
    try {
      final event = await _db.getEventById(id);
      if (event == null) return false;

      final newStatus = !event.isCompleted;
      final updated = event.copyWith(
        isCompleted: newStatus,
        updatedAt: DateTime.now(),
      );

      await _db.updateEvent(updated);

      if (newStatus) {
        // Cancel notification when marked complete
        await _notifications.cancelNotification(event.notificationId);
      } else {
        // If uncompleting, reschedule if upcoming or repeating
        await _notifications.scheduleReminderNotification(updated);
      }

      await loadEvents();

      // Sync to Supabase
      if (_supabase.isInitialized) {
        _supabase.toggleScheduleComplete(id, newStatus).catchError((e) {
          debugPrint('[EventService] Supabase toggle sync error: $e');
          return false;
        });
      }

      return true;
    } catch (e) {
      debugPrint('[EventService] Error toggling completion: $e');
      return false;
    }
  }

  /// Reschedule all active future/repeating reminders on startup or boot
  Future<void> rescheduleAllActive() async {
    try {
      final pendingEvents = await _db.getPendingRemindersToSchedule();
      debugPrint('[EventService] Rescheduling ${pendingEvents.length} active reminders...');
      for (final event in pendingEvents) {
        await _notifications.scheduleReminderNotification(event);
      }
    } catch (e) {
      debugPrint('[EventService] Error during rescheduling: $e');
    }
  }

  // Filtered views

  bool _isEventForToday(EventReminder e, DateTime now) {
    if (DateTimeUtils.isSameDay(e.date, now)) return true;
    if (DateTimeUtils.isSameDay(e.reminderDateTime, now)) return true;
    final repeat = e.repeatType.toLowerCase();
    if (repeat == 'daily') return true;
    if (repeat == 'weekly' && e.date.weekday == now.weekday) return true;
    if (repeat == 'monthly' && e.date.day == now.day) return true;
    return false;
  }

  List<EventReminder> get todayEvents {
    final now = DateTime.now();
    return _events.where((e) => _isEventForToday(e, now)).toList();
  }

  /// Early Morning Schedule (Sun): Before 12:00 PM or morning keywords
  List<EventReminder> get earlyMorningEvents {
    return todayEvents.where((e) {
      final hour = e.reminderDateTime.hour;
      final text = '${e.title} ${e.description}'.toLowerCase();
      final hasMorningKeyword = text.contains('morning') ||
          text.contains('wake') ||
          text.contains('sunrise') ||
          text.contains('sun') ||
          text.contains('early') ||
          text.contains('meditation') ||
          text.contains('yoga') ||
          text.contains('jog');
      // If keyword matches or scheduled time is before noon (5:00 AM - 11:59 AM)
      return hasMorningKeyword || (hour < 12);
    }).toList();
  }

  /// Evening Activities & Schedule (Evening): 4:00 PM – 8:00 PM (16:00 to 20:00)
  List<EventReminder> get eveningEvents {
    return todayEvents.where((e) {
      final hour = e.reminderDateTime.hour;
      final text = '${e.title} ${e.description}'.toLowerCase();
      final hasEveningKeyword = text.contains('evening') ||
          text.contains('twilight') ||
          text.contains('sunset') ||
          text.contains('walk') ||
          text.contains('workout') ||
          text.contains('gym') ||
          text.contains('tea time') ||
          text.contains('exercise');
      return hasEveningKeyword || (hour >= 16 && hour < 20);
    }).toList();
  }

  /// Night Schedule & Activities (Moon): 8:00 PM onwards or night keywords
  List<EventReminder> get nightEvents {
    return todayEvents.where((e) {
      final hour = e.reminderDateTime.hour;
      final text = '${e.title} ${e.description}'.toLowerCase();
      final hasNightKeyword = text.contains('night') ||
          text.contains('moon') ||
          text.contains('sleep') ||
          text.contains('bed') ||
          text.contains('wind down') ||
          text.contains('journal') ||
          text.contains('reflection') ||
          text.contains('dinner');
      return hasNightKeyword || (hour >= 20);
    }).toList();
  }

  /// Food & Meal Activities (Coffee): Coffee time, Breakfast, Lunch, Snacks, Total food
  List<EventReminder> get foodActivities {
    return _events.where((e) {
      final text = '${e.title} ${e.description}'.toLowerCase();
      return text.contains('coffee') ||
          text.contains('tea') ||
          text.contains('breakfast') ||
          text.contains('lunch') ||
          text.contains('snack') ||
          text.contains('snacks') ||
          text.contains('dinner') ||
          text.contains('food') ||
          text.contains('meal') ||
          text.contains('eat') ||
          text.contains('brunch') ||
          text.contains('nutrition') ||
          text.contains('water');
    }).toList();
  }

  /// Check if an event is considered a study / academic activity
  bool isStudyEvent(EventReminder e) {
    final text = '${e.title} ${e.description}'.toLowerCase();
    return text.contains('study') ||
        text.contains('class') ||
        text.contains('lecture') ||
        text.contains('reading') ||
        text.contains('read') ||
        text.contains('exam') ||
        text.contains('test') ||
        text.contains('quiz') ||
        text.contains('homework') ||
        text.contains('assignment') ||
        text.contains('course') ||
        text.contains('revision') ||
        text.contains('math') ||
        text.contains('learn');
  }

  /// One Day: That day's daily activities AND study activities
  List<EventReminder> get todayAllActivities => todayEvents;

  /// That day's daily / routine activities
  List<EventReminder> get todayDailyActivities {
    final daily = todayEvents.where((e) => !isStudyEvent(e) || e.repeatType.toLowerCase() == 'daily').toList();
    return daily.isNotEmpty ? daily : todayEvents;
  }

  /// That day's study activities
  List<EventReminder> get todayStudyActivities {
    return todayEvents.where((e) => isStudyEvent(e)).toList();
  }

  /// One Month: All monthly activities for the current month
  List<EventReminder> get currentMonthActivities {
    final now = DateTime.now();
    return _events.where((e) {
      final matchesMonth = (e.date.year == now.year && e.date.month == now.month) ||
          (e.reminderDateTime.year == now.year && e.reminderDateTime.month == now.month);
      final isDaily = e.repeatType.toLowerCase() == 'daily';
      final isWeekly = e.repeatType.toLowerCase() == 'weekly';
      final isMonthly = e.repeatType.toLowerCase() == 'monthly';
      return matchesMonth || isDaily || isWeekly || isMonthly;
    }).toList();
  }

  /// On Time: Daily activities only (active / on-time daily routine)
  List<EventReminder> get onTimeDailyActivities {
    final list = todayDailyActivities.where((e) => !e.isCompleted && !e.isOverdue).toList();
    return list.isNotEmpty ? list : todayDailyActivities.where((e) => !e.isCompleted).toList();
  }

  /// Full Study Schedule for that day (Study): Study, classes, exams, revision
  List<EventReminder> get studyEvents {
    return todayEvents.where((e) => isStudyEvent(e)).toList();
  }

  /// Future Schedule (Next Week): Beyond today into future
  List<EventReminder> get futureEvents {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return _events.where((e) {
      return e.date.isAfter(todayEnd) || e.reminderDateTime.isAfter(todayEnd);
    }).toList();
  }

  List<EventReminder> get upcomingEvents {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return _events.where((e) => !e.isCompleted && e.reminderDateTime.isAfter(todayEnd)).toList();
  }

  List<EventReminder> get ongoingTasks {
    final now = DateTime.now();
    return _events.where((e) => !e.isCompleted && _isEventForToday(e, now)).toList();
  }

  List<EventReminder> get completedEvents {
    return _events.where((e) => e.isCompleted).toList();
  }

  List<EventReminder> get overdueEvents {
    return _events.where((e) => e.isOverdue).toList();
  }

  List<EventReminder> getEventsForSelectedDate() {
    return _events.where((e) => DateTimeUtils.isSameDay(e.date, _selectedDate)).toList();
  }

  List<EventReminder> getEventsForDate(DateTime date) {
    return _events.where((e) => DateTimeUtils.isSameDay(e.date, date)).toList();
  }

  Set<int> getDaysWithEventsInMonth(DateTime month) {
    final days = <int>{};
    for (final event in _events) {
      if (event.date.year == month.year && event.date.month == month.month) {
        days.add(event.date.day);
      }
    }
    return days;
  }

  EventReminder? getEventById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
