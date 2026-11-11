import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_reminder/models/event.dart';
import 'package:schedule_reminder/models/app_state.dart';
import 'package:schedule_reminder/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupabaseService Unit & Model Mapping Tests', () {
    test('SupabaseService singleton instance exists', () {
      final service = SupabaseService.instance;
      expect(service, isNotNull);
      expect(SupabaseService.defaultUrl, 'https://helwfjurtvgzfnfvbwlr.supabase.co');
      expect(SupabaseService.defaultAnonKey, isNotEmpty);
    });

    test('EventReminder maps to and from Supabase data structures correctly', () {
      final now = DateTime(2026, 10, 10, 14, 0);
      final event = EventReminder(
        id: 'supabase-test-1',
        title: 'Project Review',
        description: 'Review Supabase integration with team',
        date: DateTime(2026, 10, 10),
        time: '02:00 PM',
        reminderDateTime: now,
        repeatType: 'None',
        repeatInterval: 1,
        isCompleted: false,
        notificationId: 999123,
        createdAt: now,
        updatedAt: now,
        priority: 'high',
      );

      final map = event.toMap();
      expect(map['id'], 'supabase-test-1');
      expect(map['title'], 'Project Review');
      expect(map['priority'], 'high');

      final reconstructed = EventReminder.fromMap(map);
      expect(reconstructed.id, event.id);
      expect(reconstructed.title, event.title);
      expect(reconstructed.description, event.description);
      expect(reconstructed.isCompleted, isFalse);
    });

    test('GoalItem maps to and from Supabase data structures correctly', () {
      final goal = GoalItem(
        id: 'supabase-goal-1',
        title: 'Complete Cloud Database Integration',
        subtitle: 'Connect schedules and goals to Supabase',
        progress: 1.0,
        category: 'Engineering',
        fromSchedule: false,
        createdAt: DateTime(2026, 10, 10, 12, 0),
      );

      final map = goal.toMap();
      expect(map['id'], 'supabase-goal-1');
      expect(map['progress'], 1.0);
      expect(map['category'], 'Engineering');

      final reconstructed = GoalItem.fromMap(map);
      expect(reconstructed.id, goal.id);
      expect(reconstructed.title, goal.title);
      expect(reconstructed.progress, 1.0);
      expect(reconstructed.category, 'Engineering');
    });

    test('testConnection returns graceful message if client uninitialized', () async {
      // In standalone unit test without Supabase.initialize
      final service = SupabaseService.instance;
      if (!service.isInitialized) {
        final result = await service.testConnection();
        expect(result['success'], isFalse);
        expect(result['message'], contains('not initialized'));
      }
    });
  });
}
