import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/event.dart';
import '../utils/date_time_utils.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String channelId = 'reminders_channel_v1';
  static const String channelName = 'Reminders & Events';
  static const String channelDescription = 'Scheduled task reminders and event alerts';

  // High-priority Heads-Up Alert Channel with sound and vibration for pop-up alerts over other apps
  static const String alertChannelId = 'schedule_alert_channel_v2';
  static const String alertChannelName = '🚨 Urgent Schedule Alerts';
  static const String alertChannelDescription = 'Heads-up alert notifications with loud sound that pop up over other apps';

  // Stream controller for tapped notifications
  final StreamController<String> _onNotificationTapController = StreamController<String>.broadcast();
  Stream<String> get onNotificationTapped => _onNotificationTapController.stream;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      debugPrint('[NotificationService] Running on Web - native notifications disabled');
      return;
    }

    // 1. Initialize timezone
    try {
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('[NotificationService] Local timezone set to: $timeZoneName');
    } catch (e) {
      debugPrint('[NotificationService] Failed to set local timezone: $e, falling back to UTC');
      try {
        tz.setLocalLocation(tz.UTC);
      } catch (_) {}
    }

    // 2. Android Initialization Settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS / Darwin Initialization Settings
    const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    // 4. Initialize Plugin
    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('[NotificationService] Notification tapped with payload: $payload');
          _onNotificationTapController.add(payload);
        }
      },
    );

    // 5. Create Android Notification Channels (Regular & High-Priority Heads-Up Alert Channel)
    final AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
      alertChannelId,
      alertChannelName,
      description: alertChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 700]),
    );

    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(defaultChannel);
      await androidImplementation.createNotificationChannel(alertChannel);
    }

    _isInitialized = true;
    debugPrint('[NotificationService] Successfully initialized');
  }

  /// Request permissions on Android (POST_NOTIFICATIONS, EXACT_ALARM) and iOS
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final notifGranted = await androidImplementation.requestNotificationsPermission();
        final exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
        debugPrint('[NotificationService] Android permissions: notif=$notifGranted, exactAlarm=$exactAlarmGranted');
        return (notifGranted ?? false);
      }
    } else if (Platform.isIOS) {
      final iosImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  /// Check if notification permissions are granted
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return true;
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final areEnabled = await androidImplementation.areNotificationsEnabled();
        return areEnabled ?? false;
      }
    }
    return true;
  }

  /// Schedule a notification for an EventReminder
  Future<bool> scheduleReminderNotification(EventReminder event) async {
    if (kIsWeb) {
      debugPrint('[NotificationService] Running on Web - native notification scheduling bypassed');
      return true;
    }
    if (!_isInitialized) await initialize();

    // Cancel any existing notification for this ID first to prevent ghosts
    await cancelNotification(event.notificationId);

    // If completed, do not schedule
    if (event.isCompleted) {
      debugPrint('[NotificationService] Event ${event.id} is completed. Skipping notification schedule.');
      return false;
    }

    DateTime scheduledTime = event.reminderDateTime;
    final now = DateTime.now();

    // Handle repeating reminders or past scheduled times
    if (event.repeatTypeEnum != RepeatType.none) {
      scheduledTime = DateTimeUtils.getNextOccurrence(
        currentScheduled: event.reminderDateTime,
        repeatType: event.repeatType,
        repeatInterval: event.repeatInterval,
      );
    } else if (scheduledTime.isBefore(now)) {
      debugPrint('[NotificationService] Non-repeating event ${event.id} scheduled in the past: $scheduledTime. Not scheduling.');
      return false;
    }

    // Convert to TZDateTime
    tz.TZDateTime tzScheduledTime;
    try {
      tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        tzScheduledTime = tzScheduledTime.add(const Duration(minutes: 1));
      }
    } catch (e) {
      debugPrint('[NotificationService] Timezone conversion error: $e');
      tzScheduledTime = tz.TZDateTime.now(tz.local).add(scheduledTime.difference(now));
    }

    final androidDetails = AndroidNotificationDetails(
      alertChannelId,
      alertChannelName,
      channelDescription: alertChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 700]),
      ticker: event.title,
      styleInformation: BigTextStyleInformation(
        event.description.isNotEmpty ? event.description : 'Reminder for ${event.title} at ${event.time}',
        contentTitle: '🚨 ${event.title}',
        summaryText: event.repeatTypeEnum != RepeatType.none ? 'Repeats: ${event.repeatType}' : 'Scheduled Reminder',
      ),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    DateTimeComponents? matchComponents;
    switch (event.repeatTypeEnum) {
      case RepeatType.daily:
        matchComponents = DateTimeComponents.time;
        break;
      case RepeatType.weekly:
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
      case RepeatType.monthly:
        matchComponents = DateTimeComponents.dayOfMonthAndTime;
        break;
      case RepeatType.yearly:
        matchComponents = DateTimeComponents.dateAndTime;
        break;
      case RepeatType.custom:
      case RepeatType.none:
        matchComponents = null;
        break;
    }

    final payload = 'popup:${event.title}|${event.time}|${event.description.isNotEmpty ? event.description : "Scheduled"}';

    try {
      await _notificationsPlugin.zonedSchedule(
        id: event.notificationId,
        title: '🚨 ${event.title}',
        body: event.description.isNotEmpty ? event.description : 'Starting at ${event.time}. Tap to respond!',
        scheduledDate: tzScheduledTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
        payload: payload,
      );

      debugPrint('[NotificationService] Scheduled notification ID: ${event.notificationId} for ${tzScheduledTime.toString()} (repeat: ${event.repeatType})');
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule exact alarm: $e. Retrying with inexact allowWhileIdle fallback.');
      try {
        await _notificationsPlugin.zonedSchedule(
          id: event.notificationId,
          title: '🚨 ${event.title}',
          body: event.description.isNotEmpty ? event.description : 'Starting at ${event.time}. Tap to respond!',
          scheduledDate: tzScheduledTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: matchComponents,
          payload: payload,
        );
        return true;
      } catch (e2) {
        debugPrint('[NotificationService] Fallback scheduling failed: $e2');
        return false;
      }
    }
  }

  /// Show an immediate test notification
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    final details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Show immediate heads-up alert notification with loud alert sound and vibration
  /// that pops up over whatever app the user is using.
  Future<void> showInstantAlertNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      alertChannelId,
      alertChannelName,
      channelDescription: alertChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 700]),
      ticker: '🚨 $title',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: '🚨 Schedule Alert',
      ),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final details = NotificationDetails(android: androidDetails, iOS: darwinDetails);
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Schedule a test heads-up alert notification with a delay (e.g. 5 seconds)
  /// so the user can test switching to another app (YouTube, WhatsApp, Browser)
  /// and seeing the alert pop up over that app with an alarm sound!
  Future<void> scheduleTestBackgroundAlert({
    String title = 'Management Accounting',
    String time = '10:00 AM – 11:00 AM',
    String location = 'Room 203',
    int delaySeconds = 5,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));
    final payload = 'popup:$title|$time|$location';

    final androidDetails = AndroidNotificationDetails(
      alertChannelId,
      alertChannelName,
      channelDescription: alertChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 700]),
      ticker: '🚨 Schedule Alert: $title',
      styleInformation: BigTextStyleInformation(
        '🔔 $title is starting at $time ($location).\nTap to respond: Are you ready?',
        contentTitle: '🚨 URGENT: $title',
        summaryText: 'Schedule Alert • Starts in minutes',
      ),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id: 888888,
        title: '🚨 $title is Starting!',
        body: 'Time: $time ($location). Tap to respond: Are you ready?',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('[NotificationService] Scheduled test background alert for ${scheduledDate.toString()}');
    } catch (e) {
      debugPrint('[NotificationService] Exact test alarm failed: $e. Retrying inexact');
      await _notificationsPlugin.zonedSchedule(
        id: 888888,
        title: '🚨 $title is Starting!',
        body: 'Time: $time ($location). Tap to respond: Are you ready?',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int notificationId) async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancel(id: notificationId);
      debugPrint('[NotificationService] Cancelled notification ID: $notificationId');
    } catch (e) {
      debugPrint('[NotificationService] Error cancelling notification $notificationId: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('[NotificationService] All notifications cancelled');
    } catch (e) {
      debugPrint('[NotificationService] Error cancelling all: $e');
    }
  }

  /// Get pending scheduled notification requests
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb) return const [];
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  void dispose() {
    _onNotificationTapController.close();
  }
}
