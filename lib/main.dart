import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/event_service.dart';
import 'services/moment_service.dart';
import 'services/supabase_service.dart';
import 'screens/event_details_screen.dart';
import 'widgets/schedule_alert_popup.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize local notification system
  await NotificationService.instance.initialize();

  // 2. Request initial permissions (POST_NOTIFICATIONS, EXACT_ALARM)
  await NotificationService.instance.requestPermissions();

  // 3. Initialize Supabase client
  try {
    await SupabaseService.instance.initialize();
  } catch (e) {
    debugPrint('[Main] Supabase init error: $e');
  }

  // 4. Initialize SQLite database & reschedule active reminders
  await EventService.instance.initialize();
  await MomentService.instance.init();

  // 5. Load theme preference
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;

  // 5. Setup notification tap listener (supports both popup alert and event detail views)
  NotificationService.instance.onNotificationTapped.listen((payload) {
    if (payload.isNotEmpty) {
      if (payload.startsWith('popup:')) {
        final content = payload.substring(6);
        final parts = content.split('|');
        final title = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : 'Management Accounting';
        final time = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : 'Now';
        final location = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : 'Room 203';

        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          ScheduleAlertPopup.show(
            context,
            title: title,
            time: time,
            location: location,
          );
        }
      } else {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(eventId: payload),
          ),
        );
      }
    }
  });

  runApp(ScheduleApp(initialDarkMode: isDark));
}

class ScheduleApp extends StatefulWidget {
  final bool initialDarkMode;
  const ScheduleApp({super.key, this.initialDarkMode = false});

  static ScheduleAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<ScheduleAppState>();

  @override
  State<ScheduleApp> createState() => ScheduleAppState();
}

class ScheduleAppState extends State<ScheduleApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  void toggleTheme(bool dark) {
    setState(() => _isDarkMode = dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'TARC',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        scaffoldBackgroundColor: AppTheme.bgCream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryOrange,
          primary: AppTheme.primaryOrange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: AppTheme.bgDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryOrange,
          primary: AppTheme.primaryOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

// Backward compatibility alias
typedef App = ScheduleApp;
