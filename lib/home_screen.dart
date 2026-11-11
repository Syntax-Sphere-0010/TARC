import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'widgets/interactive_modals.dart';
import 'screens/home_screen_tab.dart';
import 'screens/calendar_screen_tab.dart';
import 'screens/goals_screen_tab.dart';
import 'screens/profile_screen_tab.dart';
import 'screens/add_event_screen.dart';
import 'widgets/schedule_alert_popup.dart';
import 'widgets/user_avatar_widget.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;

  const HomeScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppState _appState;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _appState.currentTabIndex = widget.initialTabIndex;
    _appState.addListener(_onAppStateChanged);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  void _onAppStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _appState.dispose();
    super.dispose();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _appState.isDarkMode;

    final tabs = [
      HomeScreenTab(appState: _appState, onOpenDrawer: _openDrawer),
      CalendarScreenTab(appState: _appState, onOpenDrawer: _openDrawer),
      GoalsScreenTab(appState: _appState, onOpenDrawer: _openDrawer),
      ProfileScreenTab(appState: _appState, onOpenDrawer: _openDrawer),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgCream,
      drawer: _buildDrawer(isDark),
      body: IndexedStack(
        index: _appState.currentTabIndex,
        children: tabs,
      ),
      bottomNavigationBar: CustomAppBottomBar(
        appState: _appState,
        onAddPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEventScreen()),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppTheme.cardDark : AppTheme.bgCream,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Card in Drawer
              Row(
                children: [
                  UserAvatarWidget(
                    user: _appState.userProfile,
                    size: 52,
                    borderWidth: 2,
                    borderColor: AppTheme.primaryOrange,
                    onTap: () {
                      Navigator.pop(context);
                      _appState.setTabIndex(3);
                    },
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _appState.userProfile.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.text(isDark),
                        ),
                      ),
                      Text(
                        _appState.userProfile.role,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSub(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Divider(color: isDark ? AppTheme.borderDark : const Color(0xFFEADBCE)),
              const SizedBox(height: 12),

              Text(
                'NAVIGATION',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? AppTheme.textDarkMuted : AppTheme.textLight,
                ),
              ),

              const SizedBox(height: 8),

              _buildDrawerItem(
                index: 0,
                icon: Icons.home_rounded,
                title: 'Home / Goals',
                isDark: isDark,
              ),
              _buildDrawerItem(
                index: 1,
                icon: Icons.calendar_month_rounded,
                title: 'Calendar & Reminders',
                isDark: isDark,
              ),
              _buildDrawerItem(
                index: 2,
                icon: Icons.track_changes_rounded,
                title: 'Goals & Classes',
                isDark: isDark,
              ),
              _buildDrawerItem(
                index: 3,
                icon: Icons.person_rounded,
                title: 'My Profile',
                isDark: isDark,
              ),

              const SizedBox(height: 16),
              Divider(color: isDark ? AppTheme.borderDark : const Color(0xFFEADBCE)),
              const SizedBox(height: 12),

              Text(
                'PREFERENCES',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? AppTheme.textDarkMuted : AppTheme.textLight,
                ),
              ),

              const SizedBox(height: 8),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.nightlight_round, color: AppTheme.primaryOrange),
                title: Text(
                  'Dark Mode',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text(isDark),
                  ),
                ),
                trailing: Switch(
                  value: _appState.isDarkMode,
                  activeThumbColor: AppTheme.primaryOrange,
                  onChanged: (val) {
                    _appState.toggleDarkMode();
                  },
                ),
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_outlined, color: AppTheme.primaryOrange),
                title: Text(
                  'Notifications',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text(isDark),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  InteractiveModals.showNotificationsSheet(context, _appState);
                },
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.alarm_on_rounded, color: AppTheme.primaryOrange, size: 20),
                ),
                title: Text(
                  '🚨 Test Schedule Alert',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                subtitle: Text(
                  'Test "Are You Ready" & "Lazy" Pop-up',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSub(isDark),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScheduleAlertPopup.showTriggerChooser(
                    context,
                    title: 'Management Accounting',
                    time: '10:00 AM – 11:00 AM',
                    location: 'Room 203',
                    isDark: _appState.isDarkMode,
                  );
                },
              ),

              const Spacer(),

              // Motivational footer in drawer
              Center(
                child: Column(
                  children: [
                    Text(
                      'Make it happen ❤️',
                      style: GoogleFonts.caveat(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v1.0.0 • Schedule & Reminders',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppTheme.textDarkMuted : AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required int index,
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    final isSelected = _appState.currentTabIndex == index;
    final selectedBg = isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: isSelected ? selectedBg : Colors.transparent,
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryOrange : (isDark ? AppTheme.textDarkSecondary : AppTheme.textMuted),
        size: 22,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppTheme.primaryOrange : AppTheme.text(isDark),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        _appState.setTabIndex(index);
      },
    );
  }
}
