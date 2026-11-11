import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_reminder/home_screen.dart';
import 'package:schedule_reminder/screens/home_screen_tab.dart';
import 'package:schedule_reminder/screens/calendar_screen_tab.dart';
import 'package:schedule_reminder/screens/goals_screen_tab.dart';
import 'package:schedule_reminder/screens/profile_screen_tab.dart';

void main() {
  testWidgets('HomeScreen renders Home tab initially and switches across tabs',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Home tab is active
    expect(find.byType(HomeScreenTab), findsOneWidget);
    expect(find.text('Today'), findsAtLeast(1));
    expect(find.text('Sun'), findsAtLeast(1));
    expect(find.text('Moon'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Study'), findsAtLeast(1));
    expect(find.text('My Moments'), findsOneWidget);
    expect(find.text('My Progress'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Completed'), findsAtLeast(1));

    // Verify segmented time bar has One Day, One Month, On Time
    expect(find.text('One Day'), findsOneWidget);
    expect(find.text('One Month'), findsOneWidget);
    expect(find.text('On Time'), findsOneWidget);

    // 2. Switch to Calendar tab
    final calendarTabFinder = find.text('Calendar');
    expect(calendarTabFinder, findsOneWidget);
    await tester.tap(calendarTabFinder);
    await tester.pumpAndSettle();

    expect(find.byType(CalendarScreenTab), findsOneWidget);
    expect(find.text('TARC'), findsAtLeast(1));

    // 3. Switch to Goals tab
    final goalsTabFinder = find.text('Goals');
    expect(goalsTabFinder, findsOneWidget);
    await tester.tap(goalsTabFinder);
    await tester.pumpAndSettle();

    expect(find.byType(GoalsScreenTab), findsOneWidget);
    expect(find.text('My Goals'), findsOneWidget);
    expect(find.text('Personal Milestones'), findsOneWidget);
    expect(find.text('New Goal'), findsOneWidget);

    // 4. Switch to Profile tab
    final profileTabFinder = find.text('Profile');
    expect(profileTabFinder, findsOneWidget);
    await tester.tap(profileTabFinder);
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreenTab), findsOneWidget);
    expect(find.text('Better'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
  });
}
