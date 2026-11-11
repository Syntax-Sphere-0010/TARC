import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/interactive_modals.dart';
import '../widgets/user_avatar_widget.dart';

class ProfileScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onOpenDrawer;

  const ProfileScreen({
    super.key,
    required this.appState,
    required this.onOpenDrawer,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationGranted = false;
  bool _exactAlarmGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notif = await Permission.notification.status.isGranted;
    final exact = await Permission.scheduleExactAlarm.status.isGranted;
    if (mounted) {
      setState(() {
        _notificationGranted = notif;
        _exactAlarmGranted = exact;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    HapticFeedback.mediumImpact();
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionSettingsDialog('Notifications');
      }
    } else {
      await _checkPermissions();
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    HapticFeedback.mediumImpact();
    final status = await Permission.scheduleExactAlarm.request();
    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionSettingsDialog('Exact Alarms');
      }
    } else {
      await _checkPermissions();
    }
  }

  void _showPermissionSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          '$permissionName permission was denied. To ensure you receive timely reminders when your phone is locked or the app is closed, please enable it in Android App Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: AppTheme.text(isDark)),
          onPressed: widget.onOpenDrawer,
        ),
        title: Text(
          'Profile & Settings',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.text(isDark),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppTheme.softShadow(isDark),
                ),
                child: Row(
                  children: [
                    UserAvatarWidget(
                      user: widget.appState.userProfile,
                      size: 58,
                      borderWidth: 2.5,
                      borderColor: isDark ? AppTheme.borderDark : const Color(0xFFF0E5D8),
                      showEditBadge: true,
                      onTap: () => InteractiveModals.showAvatarPickerSheet(context, widget.appState),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.appState.userProfile.name,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.text(isDark),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.appState.userProfile.role,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: AppTheme.textSub(isDark),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '“${widget.appState.userProfile.motto}”',
                            style: GoogleFonts.caveat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryOrange),
                      onPressed: () => InteractiveModals.showEditProfileSheet(context, widget.appState),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'PREFERENCES',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textSub(isDark),
                ),
              ),

              const SizedBox(height: 10),

              // Theme Card
              Material(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                elevation: isDark ? 0 : 2,
                shadowColor: const Color(0xFFDCC8B8).withValues(alpha: 0.3),
                child: SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppTheme.primaryOrange,
                  ),
                  title: Text(
                    'Dark Mode',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text(isDark),
                    ),
                  ),
                  subtitle: Text(
                    isDark ? 'Dark theme active' : 'Warm cream light theme active',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSub(isDark)),
                  ),
                  value: widget.appState.isDarkMode,
                  activeThumbColor: AppTheme.primaryOrange,
                  onChanged: (val) async {
                    widget.appState.toggleDarkMode();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isDarkMode', val);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Android Permission Status Section
              Text(
                'ANDROID PERMISSIONS',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textSub(isDark),
                ),
              ),

              const SizedBox(height: 10),

              Material(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                elevation: isDark ? 0 : 2,
                shadowColor: const Color(0xFFDCC8B8).withValues(alpha: 0.3),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        _notificationGranted ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        color: _notificationGranted ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        'Post Notifications',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text(isDark),
                        ),
                      ),
                      subtitle: Text(
                        _notificationGranted ? 'Granted' : 'Denied - Tap to grant',
                        style: TextStyle(
                          fontSize: 12,
                          color: _notificationGranted ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: _notificationGranted
                          ? null
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              onPressed: _requestNotificationPermission,
                              child: const Text('Enable', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                      onTap: _notificationGranted ? null : _requestNotificationPermission,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        _exactAlarmGranted ? Icons.check_circle_rounded : Icons.schedule_rounded,
                        color: _exactAlarmGranted ? Colors.green : Colors.orange,
                      ),
                      title: Text(
                        'Exact Alarm Scheduling',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text(isDark),
                        ),
                      ),
                      subtitle: Text(
                        _exactAlarmGranted ? 'Exact alarms enabled' : 'Tap to verify/grant',
                        style: TextStyle(
                          fontSize: 12,
                          color: _exactAlarmGranted ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: _exactAlarmGranted
                          ? null
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              onPressed: _requestExactAlarmPermission,
                              child: const Text('Enable', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                      onTap: _exactAlarmGranted ? null : _requestExactAlarmPermission,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'TESTING & NOTIFICATIONS',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textSub(isDark),
                ),
              ),

              const SizedBox(height: 10),

              Material(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                elevation: isDark ? 0 : 2,
                shadowColor: const Color(0xFFDCC8B8).withValues(alpha: 0.3),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryOrange),
                      title: Text(
                        'Send Instant Test Notification',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text(isDark),
                        ),
                      ),
                      subtitle: Text(
                        'Verify notification delivery on your device',
                        style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSub(isDark)),
                      ),
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await NotificationService.instance.showInstantNotification(
                          id: 9999,
                          title: 'Test Notification',
                          body: 'Notifications are working perfectly on this device! 🔔',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test notification dispatched! Check your status bar.'),
                              backgroundColor: AppTheme.primaryOrange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // About & App Version
              Text(
                'ABOUT',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textSub(isDark),
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppTheme.softShadow(isDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Schedule & Reminder',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.text(isDark),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'v1.0.0',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Production-ready reminder and event scheduling app with SQLite local persistence, exact alarm scheduling, and boot recovery.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppTheme.textSub(isDark),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
