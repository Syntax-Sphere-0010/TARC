import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../models/moment.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Web in-memory caches
  List<EventReminder> _webEvents = [];
  List<Moment> _webMoments = [];
  bool _webLoaded = false;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Database is not used on Web. Fallback handles Web.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('schedule_reminders.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        await _ensureMomentsTable(db);
      },
    );
  }

  static Future<void> _ensureMomentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS moments (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        reminderDateTime TEXT NOT NULL,
        repeatType TEXT NOT NULL,
        repeatInterval INTEGER NOT NULL DEFAULT 1,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        notificationId INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        priority TEXT NOT NULL DEFAULT 'medium'
      )
    ''');

    await db.execute('CREATE INDEX idx_events_date ON events(date)');
    await db.execute('CREATE INDEX idx_events_reminder ON events(reminderDateTime)');
  }

  // --- Web Fallback Helpers ---
  Future<void> _ensureWebLoaded() async {
    if (!kIsWeb || _webLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final evStr = prefs.getString('web_events_list');
      if (evStr != null) {
        final list = jsonDecode(evStr) as List<dynamic>;
        _webEvents = list.map((m) => EventReminder.fromMap(m as Map<String, dynamic>)).toList();
      }
      final momStr = prefs.getString('web_moments_list');
      if (momStr != null) {
        final list = jsonDecode(momStr) as List<dynamic>;
        _webMoments = list.map((m) => Moment.fromMap(m as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Web load error: $e');
    }
    _webLoaded = true;
  }

  Future<void> _saveWebEvents() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _webEvents.map((e) => e.toMap()).toList();
      await prefs.setString('web_events_list', jsonEncode(list));
    } catch (e) {
      debugPrint('[DatabaseHelper] Web save events error: $e');
    }
  }

  Future<void> _saveWebMoments() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _webMoments.map((m) => m.toMap()).toList();
      await prefs.setString('web_moments_list', jsonEncode(list));
    } catch (e) {
      debugPrint('[DatabaseHelper] Web save moments error: $e');
    }
  }

  // --- Event Operations ---

  Future<int> insertEvent(EventReminder event) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      _webEvents.removeWhere((e) => e.id == event.id);
      _webEvents.add(event);
      await _saveWebEvents();
      return 1;
    }
    final db = await database;
    return await db.insert(
      'events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateEvent(EventReminder event) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final index = _webEvents.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _webEvents[index] = event;
      } else {
        _webEvents.add(event);
      }
      await _saveWebEvents();
      return 1;
    }
    final db = await database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(String id) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      _webEvents.removeWhere((e) => e.id == id);
      await _saveWebEvents();
      return 1;
    }
    final db = await database;
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<EventReminder?> getEventById(String id) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      try {
        return _webEvents.firstWhere((e) => e.id == id);
      } catch (_) {
        return null;
      }
    }
    final db = await database;
    final results = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return EventReminder.fromMap(results.first);
    }
    return null;
  }

  Future<EventReminder?> getEventByNotificationId(int notificationId) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      try {
        return _webEvents.firstWhere((e) => e.notificationId == notificationId);
      } catch (_) {
        return null;
      }
    }
    final db = await database;
    final results = await db.query(
      'events',
      where: 'notificationId = ?',
      whereArgs: [notificationId],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return EventReminder.fromMap(results.first);
    }
    return null;
  }

  Future<List<EventReminder>> getAllEvents() async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      _webEvents.sort((a, b) => a.reminderDateTime.compareTo(b.reminderDateTime));
      return List.unmodifiable(_webEvents);
    }
    final db = await database;
    final results = await db.query(
      'events',
      orderBy: 'reminderDateTime ASC, date ASC',
    );
    return results.map((map) => EventReminder.fromMap(map)).toList();
  }

  Future<List<EventReminder>> getEventsByDate(DateTime date) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      return _webEvents.where((e) {
        return e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day;
      }).toList();
    }
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final results = await db.query(
      'events',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'reminderDateTime ASC',
    );
    return results.map((map) => EventReminder.fromMap(map)).toList();
  }

  Future<List<EventReminder>> searchEvents(String query) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      if (query.trim().isEmpty) return getAllEvents();
      final q = query.toLowerCase().trim();
      return _webEvents.where((e) {
        return e.title.toLowerCase().contains(q) || e.description.toLowerCase().contains(q);
      }).toList();
    }
    final db = await database;
    if (query.trim().isEmpty) return getAllEvents();

    final pattern = '%${query.trim()}%';
    final results = await db.query(
      'events',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: [pattern, pattern],
      orderBy: 'reminderDateTime ASC',
    );
    return results.map((map) => EventReminder.fromMap(map)).toList();
  }

  Future<List<EventReminder>> getPendingRemindersToSchedule() async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      return _webEvents.where((e) => !e.isCompleted).toList();
    }
    final db = await database;
    final results = await db.query(
      'events',
      where: 'isCompleted = 0',
      orderBy: 'reminderDateTime ASC',
    );
    return results.map((map) => EventReminder.fromMap(map)).toList();
  }

  Future<int> setCompletionStatus(String id, bool isCompleted) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final idx = _webEvents.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _webEvents[idx] = _webEvents[idx].copyWith(
          isCompleted: isCompleted,
          updatedAt: DateTime.now(),
        );
        await _saveWebEvents();
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'events',
      {
        'isCompleted': isCompleted ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Moments (Progress Photos) Methods ---

  Future<int> insertMoment(Moment moment) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      _webMoments.removeWhere((m) => m.id == moment.id);
      _webMoments.insert(0, moment);
      await _saveWebMoments();
      return 1;
    }
    final db = await database;
    return await db.insert(
      'moments',
      moment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Moment>> getMoments() async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      return List.unmodifiable(_webMoments);
    }
    final db = await database;
    final results = await db.query(
      'moments',
      orderBy: 'date DESC',
    );
    return results.map((map) => Moment.fromMap(map)).toList();
  }

  Future<int> deleteMoment(String id) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      _webMoments.removeWhere((m) => m.id == id);
      await _saveWebMoments();
      return 1;
    }
    final db = await database;
    return await db.delete(
      'moments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateMoment(Moment moment) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final idx = _webMoments.indexWhere((m) => m.id == moment.id);
      if (idx != -1) {
        _webMoments[idx] = moment;
        await _saveWebMoments();
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'moments',
      moment.toMap(),
      where: 'id = ?',
      whereArgs: [moment.id],
    );
  }

  Future<void> close() async {
    if (kIsWeb) return;
    final db = await database;
    await db.close();
  }
}
