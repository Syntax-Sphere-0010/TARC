import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_reminder/main.dart';
import 'package:schedule_reminder/welcome_screen.dart';
import 'package:schedule_reminder/home_screen.dart';

void main() {
  testWidgets('ScheduleApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScheduleApp());
    expect(find.byType(ScheduleApp), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('User stays on WelcomeScreen if button is not clicked',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ScheduleApp());
    await tester.pump(const Duration(seconds: 1));

    // Stays on WelcomeScreen
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text("Let's Play"), findsOneWidget);
  });

  testWidgets('Clicking "Let\'s Play" transitions to HomeScreen',
      (WidgetTester tester) async {
    // Set a realistic mobile device height for testing full scroll view
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ScheduleApp());
    await tester.pump(const Duration(seconds: 1));

    // Tap "Let's Play" button
    final buttonFinder = find.text("Let's Play");
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // Now on HomeScreen
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Today'), findsAtLeast(1));
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Completed'), findsAtLeast(1));
  });
}
