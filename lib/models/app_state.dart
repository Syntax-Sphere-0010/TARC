import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'event.dart';
import '../services/supabase_service.dart';

enum PriorityLevel { high, medium, low }

class ReminderItem {
  final String id;
  String title;
  String time;
  PriorityLevel priority;
  IconData icon;
  Color iconColor;
  Color iconBg;
  bool isCompleted;
  DateTime date;

  ReminderItem({
    required this.id,
    required this.title,
    required this.time,
    required this.priority,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isCompleted = false,
    required this.date,
  });
}

class ClassItem {
  final String id;
  String title;
  String timeRange;
  String room;
  Color cardBg;
  Color iconColor;
  Color iconBg;
  IconData icon;
  String instructor;
  String notes;
  bool isCompleted;

  ClassItem({
    required this.id,
    required this.title,
    required this.timeRange,
    required this.room,
    this.cardBg = const Color(0xFFFFF6ED),
    this.iconColor = const Color(0xFFE86328),
    this.iconBg = const Color(0xFFFFECE0),
    this.icon = Icons.menu_book_rounded,
    this.instructor = 'Instructor',
    this.notes = '',
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'timeRange': timeRange,
      'room': room,
      'cardBg': cardBg.toARGB32(),
      'iconColor': iconColor.toARGB32(),
      'iconBg': iconBg.toARGB32(),
      'icon': icon.codePoint,
      'instructor': instructor,
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }

  static IconData _getIconFromCodePoint(int? codePoint) {
    if (codePoint == null) return Icons.menu_book_rounded;
    if (codePoint == Icons.menu_book_rounded.codePoint) return Icons.menu_book_rounded;
    if (codePoint == Icons.auto_stories_rounded.codePoint) return Icons.auto_stories_rounded;
    if (codePoint == Icons.school_rounded.codePoint) return Icons.school_rounded;
    if (codePoint == Icons.calculate_rounded.codePoint) return Icons.calculate_rounded;
    if (codePoint == Icons.psychology_rounded.codePoint) return Icons.psychology_rounded;
    if (codePoint == Icons.computer_rounded.codePoint) return Icons.computer_rounded;
    if (codePoint == Icons.assignment_rounded.codePoint) return Icons.assignment_rounded;
    if (codePoint == Icons.code_rounded.codePoint) return Icons.code_rounded;
    if (codePoint == Icons.lightbulb_rounded.codePoint) return Icons.lightbulb_rounded;
    if (codePoint == Icons.bar_chart_rounded.codePoint) return Icons.bar_chart_rounded;
    if (codePoint == Icons.science_rounded.codePoint) return Icons.science_rounded;
    if (codePoint == Icons.biotech_rounded.codePoint) return Icons.biotech_rounded;
    return Icons.menu_book_rounded;
  }

  factory ClassItem.fromMap(Map<String, dynamic> map) {
    return ClassItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      timeRange: map['timeRange'] ?? '',
      room: map['room'] ?? '',
      cardBg: map['cardBg'] != null ? Color(map['cardBg'] as int) : const Color(0xFFFFF6ED),
      iconColor: map['iconColor'] != null ? Color(map['iconColor'] as int) : const Color(0xFFE86328),
      iconBg: map['iconBg'] != null ? Color(map['iconBg'] as int) : const Color(0xFFFFECE0),
      icon: _getIconFromCodePoint(map['icon'] as int?),
      instructor: map['instructor'] ?? '',
      notes: map['notes'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class GoalItem {
  final String id;
  String title;
  String subtitle;
  double progress; // 0.0 to 1.0
  String category;
  bool fromSchedule;
  DateTime createdAt;

  GoalItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.category,
    this.fromSchedule = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'progress': progress,
      'category': category,
      'fromSchedule': fromSchedule,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GoalItem.fromMap(Map<String, dynamic> map) {
    return GoalItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'General',
      fromSchedule: map['fromSchedule'] ?? false,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : DateTime.now(),
    );
  }
}

class UserProfile {
  String name;
  String motto;
  String role;
  String email;
  String phone;
  String? avatarPath;
  int avatarPreset;
  int totalClasses;
  int completedClasses;
  int dayStreak;
  int goalsSet;

  UserProfile({
    required this.name,
    required this.motto,
    required this.role,
    this.email = 'student@example.com',
    this.phone = '+1 234 567 8900',
    this.avatarPath,
    this.avatarPreset = 0,
    required this.totalClasses,
    required this.completedClasses,
    required this.dayStreak,
    required this.goalsSet,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'motto': motto,
      'role': role,
      'email': email,
      'phone': phone,
      'avatarPath': avatarPath,
      'avatarPreset': avatarPreset,
      'totalClasses': totalClasses,
      'completedClasses': completedClasses,
      'dayStreak': dayStreak,
      'goalsSet': goalsSet,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? 'My Profile',
      motto: map['motto'] ?? 'Dream • Plan • Do',
      role: map['role'] ?? 'Student',
      email: map['email'] ?? 'student@example.com',
      phone: map['phone'] ?? '+1 234 567 8900',
      avatarPath: map['avatarPath'],
      avatarPreset: map['avatarPreset'] ?? 0,
      totalClasses: map['totalClasses'] ?? 0,
      completedClasses: map['completedClasses'] ?? 0,
      dayStreak: map['dayStreak'] ?? 1,
      goalsSet: map['goalsSet'] ?? 0,
    );
  }
}

class AppState extends ChangeNotifier {
  // Navigation
  int currentTabIndex = 0; // 0: Home, 1: Calendar, 2: Goals, 3: Profile

  // Selected date
  DateTime selectedDate = DateTime.now();

  // Time filter for home tab: 0: One Day, 1: One Month, 2: On Time
  int selectedTimeFilterIndex = 0;

  // Theme mode
  bool isDarkMode = false;

  // Profile data
  UserProfile userProfile = UserProfile(
    name: 'My Profile',
    motto: 'Dream • Plan • Do',
    role: 'Student',
    totalClasses: 0,
    completedClasses: 0,
    dayStreak: 1,
    goalsSet: 0,
  );

  // User Goals
  List<GoalItem> goals = [];

  // User Classes / Subjects (Manual add type)
  List<ClassItem> classes = [];

  // Reminders for Home Image 3 quick display
  List<ReminderItem> reminders = [];

  // Notifications list
  List<Map<String, dynamic>> notifications = [
    {
      'title': 'Welcome to Schedule & Reminders',
      'message': 'Create goals, manage your daily schedule, and stay on track!',
      'time': 'Just now',
      'unread': true,
    },
  ];

  AppState() {
    loadFromPrefs();
  }

  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Theme
      isDarkMode = prefs.getBool('isDarkMode') ?? false;

      // Profile
      final profileStr = prefs.getString('user_profile_data');
      if (profileStr != null && profileStr.isNotEmpty) {
        try {
          final map = jsonDecode(profileStr) as Map<String, dynamic>;
          userProfile = UserProfile.fromMap(map);
        } catch (e) {
          debugPrint('[AppState] Error decoding profile: $e');
        }
      }

      // Goals
      final goalsStr = prefs.getString('user_goals_data');
      if (goalsStr != null) {
        try {
          final list = jsonDecode(goalsStr) as List<dynamic>;
          goals = list.map((item) => GoalItem.fromMap(item as Map<String, dynamic>)).toList();
        } catch (e) {
          debugPrint('[AppState] Error decoding goals: $e');
        }
      } else {
        // Initial setup only once if never created
        final bool hadInitialGoals = prefs.getBool('had_initial_goals') ?? false;
        if (!hadInitialGoals) {
          goals = [
            GoalItem(
              id: 'g1',
              title: 'Study & Preparation',
              subtitle: 'Learn • Practice • Grow',
              progress: 0.65,
              category: 'Academic',
            ),
            GoalItem(
              id: 'g2',
              title: 'Health & Fitness',
              subtitle: 'Workout • Nutrition • Hydration',
              progress: 0.50,
              category: 'Wellness',
            ),
          ];
          await prefs.setBool('had_initial_goals', true);
          await _saveGoalsToPrefs();
        } else {
          goals = [];
        }
      }

      // Classes
      final classesStr = prefs.getString('user_classes_data');
      if (classesStr != null) {
        try {
          final list = jsonDecode(classesStr) as List<dynamic>;
          classes = list.map((item) => ClassItem.fromMap(item as Map<String, dynamic>)).toList();
        } catch (e) {
          debugPrint('[AppState] Error decoding classes: $e');
        }
      } else {
        // Classes are strictly manual add only. If user deletes them, they never come back.
        final bool hadInitialClasses = prefs.getBool('had_initial_classes') ?? false;
        if (!hadInitialClasses) {
          classes = [];
          await prefs.setBool('had_initial_classes', true);
        } else {
          classes = [];
        }
      }

      userProfile.goalsSet = goals.length;
      userProfile.totalClasses = classes.length;
      notifyListeners();

      // Background sync goals with Supabase
      if (SupabaseService.instance.isInitialized) {
        syncGoalsWithSupabase().catchError((e) {
          debugPrint('[AppState] Background sync goals error: $e');
        });
      }
    } catch (e) {
      debugPrint('[AppState] Error loading prefs: $e');
    }
  }

  /// Sync goals with Supabase cloud
  Future<void> syncGoalsWithSupabase() async {
    if (!SupabaseService.instance.isInitialized) return;
    try {
      final remoteGoals = await SupabaseService.instance.fetchGoals();
      if (remoteGoals.isNotEmpty) {
        for (final remote in remoteGoals) {
          final idx = goals.indexWhere((g) => g.id == remote.id);
          if (idx != -1) {
            goals[idx] = remote;
          } else {
            goals.add(remote);
          }
        }
        await _saveGoalsToPrefs();
        notifyListeners();
      } else if (goals.isNotEmpty) {
        for (final local in goals) {
          await SupabaseService.instance.saveGoal(local);
        }
      }
    } catch (e) {
      debugPrint('[AppState] syncGoalsWithSupabase error: $e');
    }
  }

  Future<void> _saveGoalsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = goals.map((g) => g.toMap()).toList();
      await prefs.setString('user_goals_data', jsonEncode(list));
      userProfile.goalsSet = goals.length;
    } catch (e) {
      debugPrint('[AppState] Error saving goals: $e');
    }
  }

  Future<void> _saveClassesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = classes.map((c) => c.toMap()).toList();
      await prefs.setString('user_classes_data', jsonEncode(list));
      userProfile.totalClasses = classes.length;
    } catch (e) {
      debugPrint('[AppState] Error saving classes: $e');
    }
  }

  Future<void> _saveProfileToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile_data', jsonEncode(userProfile.toMap()));
    } catch (e) {
      debugPrint('[AppState] Error saving profile: $e');
    }
  }

  void setTabIndex(int index) {
    currentTabIndex = index;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setTimeFilter(int index) {
    selectedTimeFilterIndex = index;
    notifyListeners();
  }

  void toggleDarkMode() async {
    isDarkMode = !isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    notifyListeners();
  }

  // --- Classes Management (Manual Add & Permanent Delete) ---
  void addClass(ClassItem item) {
    classes.add(item);
    _saveClassesToPrefs();
    notifyListeners();
  }

  void removeClass(String id) {
    classes.removeWhere((c) => c.id == id);
    _saveClassesToPrefs();
    notifyListeners();
  }

  // --- Reminders Management ---
  void addReminder(ReminderItem item) {
    reminders.add(item);
    notifyListeners();
  }

  void toggleReminderCompletion(String id) {
    final index = reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      reminders[index].isCompleted = !reminders[index].isCompleted;
      notifyListeners();
    }
  }

  void removeReminder(String id) {
    reminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // --- Goals Management (Manual Add, Progress Update, Schedule-to-Goal, Permanent Delete) ---
  void addGoal(GoalItem item) {
    goals.insert(0, item);
    _saveGoalsToPrefs();
    notifyListeners();

    if (SupabaseService.instance.isInitialized) {
      SupabaseService.instance.saveGoal(item).catchError((e) {
        debugPrint('[AppState] Supabase save goal error: $e');
        return false;
      });
    }
  }

  void removeGoal(String id) {
    goals.removeWhere((g) => g.id == id);
    _saveGoalsToPrefs();
    notifyListeners();

    if (SupabaseService.instance.isInitialized) {
      SupabaseService.instance.deleteGoal(id).catchError((e) {
        debugPrint('[AppState] Supabase delete goal error: $e');
        return false;
      });
    }
  }

  void updateGoalProgress(String id, double newProgress) {
    final index = goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      goals[index].progress = newProgress.clamp(0.0, 1.0);
      _saveGoalsToPrefs();
      notifyListeners();

      if (SupabaseService.instance.isInitialized) {
        SupabaseService.instance.updateGoalProgress(id, goals[index].progress).catchError((e) {
          debugPrint('[AppState] Supabase update goal progress error: $e');
          return false;
        });
      }
    }
  }

  /// Move/Copy an event from the schedule to the Goal section
  GoalItem moveEventToGoal(EventReminder event) {
    final newGoal = GoalItem(
      id: 'goal_from_${event.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: event.title,
      subtitle: event.description.isNotEmpty
          ? event.description
          : 'Scheduled: ${event.time} • ${event.repeatType}',
      progress: event.isCompleted ? 1.0 : 0.0,
      category: event.priority == 'high'
          ? 'Priority Goal'
          : (event.title.toLowerCase().contains('study') ||
                  event.title.toLowerCase().contains('exam') ||
                  event.title.toLowerCase().contains('class'))
              ? 'Academic'
              : 'Schedule',
      fromSchedule: true,
      createdAt: DateTime.now(),
    );

    goals.insert(0, newGoal);
    _saveGoalsToPrefs();
    notifyListeners();
    return newGoal;
  }

  // --- Profile Management ---
  void updateProfile({
    String? name,
    String? motto,
    String? role,
    String? email,
    String? phone,
    String? avatarPath,
    int? avatarPreset,
  }) {
    if (name != null && name.trim().isNotEmpty) userProfile.name = name.trim();
    if (motto != null && motto.trim().isNotEmpty) userProfile.motto = motto.trim();
    if (role != null && role.trim().isNotEmpty) userProfile.role = role.trim();
    if (email != null && email.trim().isNotEmpty) userProfile.email = email.trim();
    if (phone != null && phone.trim().isNotEmpty) userProfile.phone = phone.trim();
    if (avatarPath != null) userProfile.avatarPath = avatarPath;
    if (avatarPreset != null) userProfile.avatarPreset = avatarPreset;

    _saveProfileToPrefs();
    notifyListeners();
  }
}
