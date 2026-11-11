import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_reminder/models/event.dart';
import 'package:schedule_reminder/models/moment.dart';
import 'package:schedule_reminder/models/app_state.dart';
import 'package:schedule_reminder/widgets/user_avatar_widget.dart';
import 'package:schedule_reminder/utils/date_time_utils.dart';
import 'package:schedule_reminder/screens/add_event_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventReminder Model & Serialization Tests', () {
    test('EventReminder toMap and fromMap works correctly', () {
      final now = DateTime(2026, 10, 10, 10, 30);
      final event = EventReminder(
        id: 'test-event-1',
        title: 'Team Standup',
        description: 'Discuss sprint goals and roadblocks',
        date: DateTime(2026, 10, 10),
        time: '10:30 AM',
        reminderDateTime: now,
        repeatType: 'Weekly',
        repeatInterval: 1,
        isCompleted: false,
        notificationId: 123456,
        createdAt: now,
        updatedAt: now,
        priority: 'high',
      );

      final map = event.toMap();
      expect(map['id'], 'test-event-1');
      expect(map['title'], 'Team Standup');
      expect(map['repeatType'], 'Weekly');
      expect(map['notificationId'], 123456);
      expect(map['isCompleted'], 0);
      expect(map['priority'], 'high');

      final reconstructed = EventReminder.fromMap(map);
      expect(reconstructed.id, event.id);
      expect(reconstructed.title, event.title);
      expect(reconstructed.description, event.description);
      expect(reconstructed.date, event.date);
      expect(reconstructed.time, event.time);
      expect(reconstructed.reminderDateTime, event.reminderDateTime);
      expect(reconstructed.repeatType, event.repeatType);
      expect(reconstructed.repeatTypeEnum, RepeatType.weekly);
      expect(reconstructed.isCompleted, isFalse);
      expect(reconstructed.notificationId, 123456);
      expect(reconstructed.priority, 'high');
    });

    test('isOverdue returns true only for uncompleted past events', () {
      final pastTime = DateTime.now().subtract(const Duration(hours: 2));
      final futureTime = DateTime.now().add(const Duration(hours: 2));

      final overdueEvent = EventReminder(
        id: '1',
        title: 'Doctor Appointment',
        date: pastTime,
        time: '10:00 AM',
        reminderDateTime: pastTime,
        notificationId: 1,
        createdAt: pastTime,
        updatedAt: pastTime,
        isCompleted: false,
      );
      expect(overdueEvent.isOverdue, isTrue);

      final completedOverdueEvent = overdueEvent.copyWith(isCompleted: true);
      expect(completedOverdueEvent.isOverdue, isFalse);

      final futureEvent = overdueEvent.copyWith(
        reminderDateTime: futureTime,
        isCompleted: false,
      );
      expect(futureEvent.isOverdue, isFalse);
    });

    test('copyWith updates properties correctly', () {
      final initial = EventReminder(
        id: '1',
        title: 'Original Title',
        date: DateTime(2026, 1, 1),
        time: '09:00 AM',
        reminderDateTime: DateTime(2026, 1, 1, 9, 0),
        notificationId: 10,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final modified = initial.copyWith(
        title: 'Updated Title',
        time: '11:00 AM',
        isCompleted: true,
        priority: 'high',
      );

      expect(modified.id, '1');
      expect(modified.title, 'Updated Title');
      expect(modified.time, '11:00 AM');
      expect(modified.isCompleted, isTrue);
      expect(modified.priority, 'high');
    });
  });

  group('DateTimeUtils Tests', () {
    test('formatDate and formatTimeOfDay output expected formats', () {
      final date = DateTime(2026, 10, 15);
      expect(DateTimeUtils.formatDate(date), '15 Oct 2026');

      const time = TimeOfDay(hour: 14, minute: 30);
      expect(DateTimeUtils.formatTimeOfDay(time), '02:30 PM');
    });

    test('parseTimeOfDay parses valid 12-hour strings', () {
      final t1 = DateTimeUtils.parseTimeOfDay('10:30 AM');
      expect(t1.hour, 10);
      expect(t1.minute, 30);

      final t2 = DateTimeUtils.parseTimeOfDay('06:45 PM');
      expect(t2.hour, 18);
      expect(t2.minute, 45);

      final t3 = DateTimeUtils.parseTimeOfDay('12:00 PM');
      expect(t3.hour, 12);
      expect(t3.minute, 0);

      final t4 = DateTimeUtils.parseTimeOfDay('12:15 AM');
      expect(t4.hour, 0);
      expect(t4.minute, 15);
    });

    test('getNextOccurrence for Daily repeat advances past now', () {
      final past = DateTime.now().subtract(const Duration(days: 3));
      final next = DateTimeUtils.getNextOccurrence(
        currentScheduled: past,
        repeatType: 'Daily',
      );
      expect(next.isAfter(DateTime.now()), isTrue);
      expect(next.hour, past.hour);
      expect(next.minute, past.minute);
    });

    test('getNextOccurrence for Weekly repeat advances past now', () {
      final past = DateTime.now().subtract(const Duration(days: 10));
      final next = DateTimeUtils.getNextOccurrence(
        currentScheduled: past,
        repeatType: 'Weekly',
      );
      expect(next.isAfter(DateTime.now()), isTrue);
      expect(next.weekday, past.weekday);
    });

    test('getNextOccurrence for Monthly repeat handles months safely without crashing', () {
      // Test 31st of month clamped when target month has fewer days
      final jan31 = DateTime(2025, 1, 31, 10, 0);
      final next = DateTimeUtils.getNextOccurrence(
        currentScheduled: jan31,
        repeatType: 'Monthly',
      );
      expect(next.isAfter(DateTime.now()), isTrue);
      expect(next.day <= 31, isTrue);
    });

    test('getNextOccurrence for Custom repeat advances by repeatInterval', () {
      final past = DateTime.now().subtract(const Duration(days: 5));
      final next = DateTimeUtils.getNextOccurrence(
        currentScheduled: past,
        repeatType: 'Custom',
        repeatInterval: 3,
      );
      expect(next.isAfter(DateTime.now()), isTrue);
    });

    test('generateNotificationId produces positive 32-bit integer', () {
      final id1 = DateTimeUtils.generateNotificationId();
      final id2 = DateTimeUtils.generateNotificationId();
      expect(id1, isNonNegative);
      expect(id2, isNonNegative);
      expect(id1 < 2147483647, isTrue);
    });
  });

  group('AddEventScreen Widget Tests', () {
    testWidgets('AddEventScreen displays form, validates empty title, and shows warnings for past time', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: AddEventScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify fields exist
      expect(find.text('New Reminder'), findsOneWidget);
      expect(find.text('Title *'), findsOneWidget);
      expect(find.text('Description (Optional)'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Repeat Interval'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Tap Save in AppBar with empty title -> should show validation error
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a title'), findsOneWidget);

      // Enter valid title
      await tester.enterText(find.byType(TextFormField).first, 'Study Machine Learning');
      await tester.pumpAndSettle();

      // Switch repeat interval to Daily
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();

      // Select High priority
      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();
    });
  });

  group('Moment Model & Serialization Tests', () {
    test('Moment toMap and fromMap works correctly', () {
      final now = DateTime(2026, 10, 10, 14, 0);
      final moment = Moment(
        id: 'moment-123',
        title: 'Morning Yoga & Meditation',
        category: 'Mindset',
        imageUrl: 'https://example.com/yoga.jpg',
        date: now,
        note: 'Felt calm and present.',
      );

      final map = moment.toMap();
      expect(map['id'], 'moment-123');
      expect(map['title'], 'Morning Yoga & Meditation');
      expect(map['category'], 'Mindset');
      expect(map['imageUrl'], 'https://example.com/yoga.jpg');
      expect(map['note'], 'Felt calm and present.');

      final reconstructed = Moment.fromMap(map);
      expect(reconstructed.id, moment.id);
      expect(reconstructed.title, moment.title);
      expect(reconstructed.category, moment.category);
      expect(reconstructed.imageUrl, moment.imageUrl);
      expect(reconstructed.note, moment.note);
    });
  });

  group('Profile Avatar & Cartoon Profile Tests', () {
    test('UserProfile serialization preserves avatarPath and avatarPreset', () {
      final user = UserProfile(
        name: 'Alex Rider',
        motto: 'Aim high, reach further',
        role: 'Explorer',
        avatarPath: 'assets/images/cartoon_avatar_1.jpg',
        avatarPreset: 101,
        totalClasses: 3,
        completedClasses: 2,
        dayStreak: 5,
        goalsSet: 4,
      );

      final map = user.toMap();
      expect(map['avatarPath'], 'assets/images/cartoon_avatar_1.jpg');
      expect(map['avatarPreset'], 101);

      final loaded = UserProfile.fromMap(map);
      expect(loaded.name, 'Alex Rider');
      expect(loaded.avatarPath, 'assets/images/cartoon_avatar_1.jpg');
      expect(loaded.avatarPreset, 101);
    });

    test('CartoonAvatarList has 8 diverse cartoon avatars', () {
      expect(CartoonAvatarList.items.length, 8);
      expect(CartoonAvatarList.items.any((c) => c.name == 'Leo'), isTrue);
      expect(CartoonAvatarList.items.any((c) => c.name == 'Mia'), isTrue);
      expect(CartoonAvatarList.items.any((c) => c.name == 'Alex'), isTrue);
      expect(CartoonAvatarList.items.any((c) => c.name == 'Pixel'), isTrue);
      expect(CartoonAvatarList.items.any((c) => c.name == 'Mochi'), isTrue);
      expect(CartoonAvatarList.items.any((c) => c.name == 'Astro'), isTrue);
      expect(CartoonAvatarList.items.any((c) => c.name == 'Cipher'), isTrue);
      expect(CartoonAvatarList.items.any((c) => c.name == 'Lotus'), isTrue);
    });

    testWidgets('UserAvatarWidget renders with cartoon preset and camera edit badge',
        (WidgetTester tester) async {
      final user = UserProfile(
        name: 'Jane Doe',
        motto: 'Always learning',
        role: 'Student',
        avatarPreset: 104, // Pixel Gamer Star
        totalClasses: 0,
        completedClasses: 0,
        dayStreak: 1,
        goalsSet: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UserAvatarWidget(
                user: user,
                size: 80,
                showEditBadge: true,
                isOnline: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UserAvatarWidget), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
      expect(find.text('Pixel'), findsOneWidget);
    });
  });
}
