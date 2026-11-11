import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';
import '../models/app_state.dart';

/// Reusable service for all Supabase database & authentication operations.
class SupabaseService with ChangeNotifier {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  /// Canonical Supabase URL for project 'helwfjurtvgzfnfvbwlr'
  static const String defaultUrl = 'https://helwfjurtvgzfnfvbwlr.supabase.co';

  /// Safe publishable/anon API key
  static const String defaultAnonKey = 'sb_publishable_4QHZtTs14hbdDKKa3FQf9g_TllfJSWL';

  bool _isInitialized = false;
  bool _isSyncing = false;
  String? _lastError;
  DateTime? _lastSyncTime;

  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;

  SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => client?.auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  /// Initialize Supabase client
  Future<bool> initialize({
    String url = defaultUrl,
    String anonKey = defaultAnonKey,
  }) async {
    try {
      // Normalize URL if user pasted dashboard URL by mistake
      String resolvedUrl = url.trim();
      if (resolvedUrl.contains('supabase.com/dashboard/project/')) {
        final regex = RegExp(r'project\/([a-zA-Z0-9_-]+)');
        final match = regex.firstMatch(resolvedUrl);
        if (match != null && match.groupCount >= 1) {
          final projectRef = match.group(1);
          resolvedUrl = 'https://$projectRef.supabase.co';
        }
      }

      await Supabase.initialize(
        url: resolvedUrl,
        // ignore: deprecated_member_use
        anonKey: anonKey.trim(),
      );

      _isInitialized = true;
      _lastError = null;
      debugPrint('[SupabaseService] Initialized successfully with $resolvedUrl');
      notifyListeners();
      return true;
    } catch (e) {
      _isInitialized = false;
      _lastError = e.toString();
      debugPrint('[SupabaseService] Initialization failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// Live test connection to Supabase
  Future<Map<String, dynamic>> testConnection() async {
    final client = this.client;
    if (client == null) {
      return {
        'success': false,
        'message': 'Supabase client is not initialized.',
        'latencyMs': 0,
      };
    }

    final stopwatch = Stopwatch()..start();
    try {
      // Attempt a lightweight select on schedules or goals table, or auth health
      await client.from('schedules').select('id').limit(1);
      stopwatch.stop();

      return {
        'success': true,
        'message': 'Connected to Supabase project successfully! Table "schedules" is ready.',
        'latencyMs': stopwatch.elapsedMilliseconds,
        'user': currentUser?.email ?? (currentUser != null ? 'Authenticated (${currentUser!.id.substring(0, 8)}...)' : 'Anonymous / Guest'),
      };
    } catch (e) {
      stopwatch.stop();
      final errStr = e.toString();
      // If table doesn't exist yet, but server answered, connection is still valid!
      if (errStr.contains('relation') || errStr.contains('does not exist') || errStr.contains('PGRST205') || errStr.contains('42P01')) {
        return {
          'success': true,
          'message': 'Connected to Supabase! (Tables need to be created using the provided SQL script).',
          'latencyMs': stopwatch.elapsedMilliseconds,
          'tablesNeeded': true,
        };
      }

      return {
        'success': false,
        'message': 'Connection error: $e',
        'latencyMs': stopwatch.elapsedMilliseconds,
      };
    }
  }

  // ==========================================
  // SCHEDULES (EventReminder) CRUD OPERATIONS
  // ==========================================

  /// Fetch all schedules from Supabase
  Future<List<EventReminder>> fetchSchedules() async {
    final client = this.client;
    if (client == null) return [];

    try {
      final response = await client
          .from('schedules')
          .select()
          .order('date', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => _mapToEventReminder(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[SupabaseService] fetchSchedules error: $e');
      return [];
    }
  }

  /// Save or update a schedule in Supabase
  Future<bool> saveSchedule(EventReminder event) async {
    final client = this.client;
    if (client == null) return false;

    try {
      final data = _eventReminderToMap(event);
      await client.from('schedules').upsert(data, onConflict: 'id');
      debugPrint('[SupabaseService] Schedule synced to Supabase: ${event.title}');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] saveSchedule error: $e');
      return false;
    }
  }

  /// Update an existing schedule in Supabase
  Future<bool> updateSchedule(EventReminder event) async {
    return await saveSchedule(event);
  }

  /// Delete a schedule from Supabase
  Future<bool> deleteSchedule(String id) async {
    final client = this.client;
    if (client == null) return false;

    try {
      await client.from('schedules').delete().eq('id', id);
      debugPrint('[SupabaseService] Schedule deleted from Supabase: $id');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] deleteSchedule error: $e');
      return false;
    }
  }

  /// Toggle completion status of a schedule
  Future<bool> toggleScheduleComplete(String id, bool isCompleted) async {
    final client = this.client;
    if (client == null) return false;

    try {
      await client.from('schedules').update({
        'is_completed': isCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] toggleScheduleComplete error: $e');
      return false;
    }
  }

  // ==========================================
  // GOALS (GoalItem) CRUD OPERATIONS
  // ==========================================

  /// Fetch all goals from Supabase
  Future<List<GoalItem>> fetchGoals() async {
    final client = this.client;
    if (client == null) return [];

    try {
      final response = await client
          .from('goals')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => _mapToGoalItem(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[SupabaseService] fetchGoals error: $e');
      return [];
    }
  }

  /// Save or update a goal in Supabase
  Future<bool> saveGoal(GoalItem goal) async {
    final client = this.client;
    if (client == null) return false;

    try {
      final data = _goalItemToMap(goal);
      await client.from('goals').upsert(data, onConflict: 'id');
      debugPrint('[SupabaseService] Goal synced to Supabase: ${goal.title}');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] saveGoal error: $e');
      return false;
    }
  }

  /// Update goal progress in Supabase
  Future<bool> updateGoalProgress(String id, double progress) async {
    final client = this.client;
    if (client == null) return false;

    try {
      await client.from('goals').update({
        'progress': progress,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] updateGoalProgress error: $e');
      return false;
    }
  }

  /// Delete a goal from Supabase
  Future<bool> deleteGoal(String id) async {
    final client = this.client;
    if (client == null) return false;

    try {
      await client.from('goals').delete().eq('id', id);
      debugPrint('[SupabaseService] Goal deleted from Supabase: $id');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] deleteGoal error: $e');
      return false;
    }
  }

  // ==========================================
  // SYNC ENGINE (Two-way reconciliation)
  // ==========================================

  /// Perform a full bi-directional sync
  Future<void> syncAll({
    required List<EventReminder> localEvents,
    required List<GoalItem> localGoals,
    required Future<void> Function(List<EventReminder> remoteEvents) onEventsMerged,
    required Future<void> Function(List<GoalItem> remoteGoals) onGoalsMerged,
  }) async {
    if (!_isInitialized || _isSyncing) return;

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      // 1. Sync Schedules
      final remoteEvents = await fetchSchedules();
      if (remoteEvents.isNotEmpty) {
        await onEventsMerged(remoteEvents);
      } else if (localEvents.isNotEmpty) {
        // First-time push to remote
        for (final event in localEvents) {
          await saveSchedule(event);
        }
      }

      // 2. Sync Goals
      final remoteGoals = await fetchGoals();
      if (remoteGoals.isNotEmpty) {
        await onGoalsMerged(remoteGoals);
      } else if (localGoals.isNotEmpty) {
        // First-time push to remote
        for (final goal in localGoals) {
          await saveGoal(goal);
        }
      }

      _lastSyncTime = DateTime.now();
      debugPrint('[SupabaseService] Full sync completed at $_lastSyncTime');
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[SupabaseService] Full sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ==========================================
  // AUTHENTICATION UTILITIES
  // ==========================================

  /// Sign in anonymously (if enabled in Supabase project)
  Future<AuthResponse?> signInAnonymously() async {
    final client = this.client;
    if (client == null) return null;
    try {
      final res = await client.auth.signInAnonymously();
      notifyListeners();
      return res;
    } catch (e) {
      debugPrint('[SupabaseService] signInAnonymously error: $e');
      return null;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse?> signInWithEmail(String email, String password) async {
    final client = this.client;
    if (client == null) return null;
    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return res;
    } catch (e) {
      debugPrint('[SupabaseService] signInWithEmail error: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AuthResponse?> signUpWithEmail(String email, String password) async {
    final client = this.client;
    if (client == null) return null;
    try {
      final res = await client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return res;
    } catch (e) {
      debugPrint('[SupabaseService] signUpWithEmail error: $e');
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    final client = this.client;
    if (client == null) return;
    try {
      await client.auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('[SupabaseService] signOut error: $e');
    }
  }

  // ==========================================
  // PRIVATE MAPPER HELPERS
  // ==========================================

  Map<String, dynamic> _eventReminderToMap(EventReminder event) {
    return {
      'id': event.id,
      if (currentUserId != null) 'user_id': currentUserId,
      'title': event.title,
      'description': event.description,
      'date': event.date.toIso8601String(),
      'time': event.time,
      'reminder_date_time': event.reminderDateTime.toIso8601String(),
      'repeat_type': event.repeatType,
      'repeat_interval': event.repeatInterval,
      'is_completed': event.isCompleted,
      'notification_id': event.notificationId,
      'priority': event.priority,
      'created_at': event.createdAt.toIso8601String(),
      'updated_at': event.updatedAt.toIso8601String(),
    };
  }

  EventReminder _mapToEventReminder(Map<String, dynamic> map) {
    return EventReminder(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: (map['description'] as String?) ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      time: map['time']?.toString() ?? '',
      reminderDateTime: DateTime.tryParse(
            (map['reminder_date_time'] ?? map['reminderDateTime'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      repeatType: (map['repeat_type'] ?? map['repeatType'])?.toString() ?? 'None',
      repeatInterval: (map['repeat_interval'] ?? map['repeatInterval'] as num?)?.toInt() ?? 1,
      isCompleted: (map['is_completed'] ?? map['isCompleted']) == true ||
          (map['is_completed'] ?? map['isCompleted']) == 1,
      notificationId: (map['notification_id'] ?? map['notificationId'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(
            (map['created_at'] ?? map['createdAt'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
            (map['updated_at'] ?? map['updatedAt'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      priority: (map['priority'] as String?) ?? 'medium',
    );
  }

  Map<String, dynamic> _goalItemToMap(GoalItem goal) {
    return {
      'id': goal.id,
      if (currentUserId != null) 'user_id': currentUserId,
      'title': goal.title,
      'subtitle': goal.subtitle,
      'progress': goal.progress,
      'category': goal.category,
      'from_schedule': goal.fromSchedule,
      'created_at': goal.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  GoalItem _mapToGoalItem(Map<String, dynamic> map) {
    return GoalItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: (map['subtitle'] as String?) ?? '',
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      category: (map['category'] as String?) ?? 'General',
      fromSchedule: (map['from_schedule'] ?? map['fromSchedule']) == true ||
          (map['from_schedule'] ?? map['fromSchedule']) == 1,
      createdAt: DateTime.tryParse(
            (map['created_at'] ?? map['createdAt'])?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
