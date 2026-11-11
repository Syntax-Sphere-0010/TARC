import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedule_reminder/widgets/schedule_alert_popup.dart';

void main() {
  testWidgets('ScheduleAlertPopup displays title, buttons, and handles Lazy click correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  ScheduleAlertPopup.show(
                    context,
                    title: 'Management Accounting',
                    time: '10:00 AM – 11:00 AM',
                    location: 'Room 203',
                  );
                },
                child: const Text('Open Alert'),
              );
            },
          ),
        ),
      ),
    );

    // Tap to open the alert pop-up
    await tester.tap(find.text('Open Alert'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify pop-up content is displayed
    expect(find.text('SCHEDULE STARTING NOW'), findsOneWidget);
    expect(find.text('Management Accounting'), findsOneWidget);
    expect(find.text('10:00 AM – 11:00 AM'), findsOneWidget);
    expect(find.text('Room 203'), findsOneWidget);

    // Verify the two required buttons are present
    expect(find.text('Are You Ready'), findsOneWidget);
    expect(find.text('Lazy'), findsOneWidget);

    // Verify "Can't Do Anything In That Behaviour" is NOT visible before tapping "Lazy"
    expect(find.text("Can't Do Anything In That Behaviour"), findsNothing);

    // Tap "Lazy" button
    await tester.tap(find.text('Lazy'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 350));

    // Verify the exact message appears
    expect(find.text("Can't Do Anything In That Behaviour"), findsOneWidget);

    // Advance time by 2 seconds (the auto-close duration)
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify the pop-up has automatically closed
    expect(find.text('SCHEDULE STARTING NOW'), findsNothing);
    expect(find.text("Can't Do Anything In That Behaviour"), findsNothing);
    expect(find.text('Open Alert'), findsOneWidget);
  });

  testWidgets('ScheduleAlertPopup "Are You Ready" button functions and triggers callback', (WidgetTester tester) async {
    bool wasReadyCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  ScheduleAlertPopup.show(
                    context,
                    title: 'Business Communication',
                    time: '01:30 PM – 02:45 PM',
                    location: 'Auditorium B',
                    onReady: () {
                      wasReadyCalled = true;
                    },
                  );
                },
                child: const Text('Open Alert 2'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Alert 2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Are You Ready'), findsOneWidget);
    await tester.tap(find.text('Are You Ready'));
    await tester.pump();

    expect(wasReadyCalled, isTrue);

    // Wait for the ready confirmation timer to pop
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify pop-up is dismissed
    expect(find.text('Business Communication'), findsNothing);
  });

  testWidgets('ScheduleAlertPopup.showTriggerChooser displays options for in-app and background alerts', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  ScheduleAlertPopup.showTriggerChooser(
                    context,
                    title: 'Strategic Management',
                    time: '03:00 PM – 04:00 PM',
                    location: 'Room 101',
                  );
                },
                child: const Text('Open Chooser'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Chooser'));
    await tester.pumpAndSettle();

    // Verify chooser content
    expect(find.text('🚨 Trigger Schedule Alert'), findsOneWidget);
    expect(find.text('Pop-up Right Now (In-App)'), findsOneWidget);
    expect(find.text('Pop-up Over Another App (5s Delay)'), findsOneWidget);

    // Tap in-app option
    await tester.tap(find.text('Pop-up Right Now (In-App)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify popup is now active on screen
    expect(find.text('SCHEDULE STARTING NOW'), findsOneWidget);
    expect(find.text('Strategic Management'), findsOneWidget);

    // Dismiss dialog to clean up animation controller
    Navigator.of(tester.element(find.text('SCHEDULE STARTING NOW')), rootNavigator: true).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });
}
