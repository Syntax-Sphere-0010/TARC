import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

/// Shows the Schedule Begin Alert Pop-up over any screen or view
class ScheduleAlertPopup extends StatefulWidget {
  final String title;
  final String time;
  final String location;
  final bool isDark;
  final VoidCallback? onReady;

  const ScheduleAlertPopup({
    super.key,
    required this.title,
    required this.time,
    this.location = 'Room 203',
    this.isDark = false,
    this.onReady,
  });

  /// Static helper to trigger the alert pop-up from anywhere
  static Future<void> show(
    BuildContext context, {
    String title = 'Management Accounting',
    String time = '10:00 AM – 11:00 AM',
    String location = 'Room 203',
    bool isDark = false,
    VoidCallback? onReady,
  }) {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => ScheduleAlertPopup(
        title: title,
        time: time,
        location: location,
        isDark: isDark,
        onReady: onReady,
      ),
    );
  }

  /// Displays a chooser so the user can test the pop-up immediately in-app,
  /// or schedule a background alert that pops up over another app with sound!
  static void showTriggerChooser(
    BuildContext context, {
    String title = 'Management Accounting',
    String time = '10:00 AM – 11:00 AM',
    String location = 'Room 203',
    bool isDark = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppTheme.primaryOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🚨 Trigger Schedule Alert',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'With alert sound & heads-up pop-up',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Option 1: Pop-up right now
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppTheme.primaryOrange.withValues(alpha: 0.3)),
                  ),
                  tileColor: AppTheme.primaryOrange.withValues(alpha: 0.05),
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.touch_app_rounded),
                  ),
                  title: Text(
                    'Pop-up Right Now (In-App)',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Triggers "Are You Ready" pop-up instantly with alert sound chime',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScheduleAlertPopup.show(
                      context,
                      title: title,
                      time: time,
                      location: location,
                      isDark: isDark,
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Option 2: Test over other apps in 5 seconds
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  tileColor: Colors.redAccent.withValues(alpha: 0.05),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.open_in_browser_rounded),
                  ),
                  title: Text(
                    'Pop-up Over Another App (5s Delay)',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Switch to WhatsApp, YouTube, or Chrome. Alert banner drops down with loud alarm sound!',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    NotificationService.instance.scheduleTestBackgroundAlert(
                      title: title,
                      time: time,
                      location: location,
                      delaySeconds: 5,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF1E1E2C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        content: Row(
                          children: [
                            const Icon(Icons.timer_rounded, color: AppTheme.primaryOrange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '⏰ Alert scheduled in 5s! Switch to another app now to see the alert drop down with sound.',
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  State<ScheduleAlertPopup> createState() => _ScheduleAlertPopupState();
}

class _ScheduleAlertPopupState extends State<ScheduleAlertPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _bellCtrl;
  late Animation<double> _bellAngle;

  bool _isLazyClicked = false;
  bool _isReadyClicked = false;
  Timer? _autoCloseTimer;
  double _countdownProgress = 1.0;
  Timer? _progressTimer;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    // Continuous vibration and ringing bell animation
    _bellCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _bellAngle = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _bellCtrl, curve: Curves.easeInOut),
    );

    // Initial alert sound and haptic vibration alert
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    _pulseTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.vibrate();
      }
    });
  }

  @override
  void dispose() {
    _bellCtrl.dispose();
    _autoCloseTimer?.cancel();
    _progressTimer?.cancel();
    _pulseTimer?.cancel();
    super.dispose();
  }

  void _onLazyPressed() {
    if (_isLazyClicked || _isReadyClicked) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isLazyClicked = true;
      _countdownProgress = 1.0;
    });

    // Animate countdown bar over 2 seconds
    const intervalMs = 50;
    const totalMs = 2000;
    int elapsedMs = 0;

    _progressTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      elapsedMs += intervalMs;
      if (mounted) {
        setState(() {
          _countdownProgress = (1.0 - (elapsedMs / totalMs)).clamp(0.0, 1.0);
        });
      }
      if (elapsedMs >= totalMs) {
        timer.cancel();
      }
    });

    // Exact 2 seconds wait, then automatically close
    _autoCloseTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  void _onReadyPressed() {
    if (_isLazyClicked || _isReadyClicked) return;
    HapticFeedback.heavyImpact();

    setState(() {
      _isReadyClicked = true;
    });

    widget.onReady?.call();

    Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Great spirit! Starting "${widget.title}" now 🔥'),
            backgroundColor: AppTheme.primaryOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF221E1A) : Colors.white;
    final primaryTextColor = AppTheme.text(isDark);
    final subTextColor = AppTheme.textSub(isDark);

    return PopScope(
      canPop: false,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? AppTheme.borderDark : const Color(0xFFF3E7DC),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOrange.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Ringing Alarm Header Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                      ),
                    ),
                    RotationTransition(
                      turns: _bellAngle,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8B48), AppTheme.primaryOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Alert Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECE0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'SCHEDULE STARTING NOW',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryOrange,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Title & Subtitle
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: subTextColor),
                    const SizedBox(width: 4),
                    Text(
                      widget.time,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(color: subTextColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.location_on_outlined, size: 14, color: subTextColor),
                    const SizedBox(width: 2),
                    Text(
                      widget.location,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // 4. Two Buttons: "Are You Ready" and "Lazy"
                Row(
                  children: [
                    // Button 1: "Are You Ready"
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isReadyClicked
                              ? const Color(0xFF4CAF50)
                              : AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLazyClicked ? null : _onReadyPressed,
                        icon: Icon(
                          _isReadyClicked ? Icons.check_circle_rounded : Icons.flash_on_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _isReadyClicked ? 'Ready!' : 'Are You Ready',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Button 2: "Lazy"
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _isLazyClicked
                              ? const Color(0xFFFBEBE8)
                              : (isDark ? const Color(0xFF2C241E) : const Color(0xFFFAF5EF)),
                          foregroundColor: _isLazyClicked
                              ? const Color(0xFFDE4536)
                              : (isDark ? AppTheme.textDarkSecondary : const Color(0xFF7A6B5D)),
                          side: BorderSide(
                            color: _isLazyClicked
                                ? const Color(0xFFDE4536)
                                : (isDark ? AppTheme.borderDark : const Color(0xFFEADBCE)),
                            width: 1.3,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isReadyClicked ? null : _onLazyPressed,
                        icon: const Icon(Icons.bedtime_outlined, size: 16),
                        label: Text(
                          'Lazy',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // 5. Special Lazy Response Container (Appears for 2 seconds when "Lazy" is clicked)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SizeTransition(sizeFactor: anim, child: child),
                  ),
                  child: _isLazyClicked
                      ? Container(
                          key: const ValueKey('lazy_message_box'),
                          margin: const EdgeInsets.only(top: 18),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF381F1B) : const Color(0xFFFFECE8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFDE4536).withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFDE4536),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      "Can't Do Anything In That Behaviour",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? const Color(0xFFFFB4AB)
                                            : const Color(0xFFC72819),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // 2-second countdown indicator bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _countdownProgress,
                                  backgroundColor: Colors.black.withValues(alpha: 0.1),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFDE4536),
                                  ),
                                  minHeight: 3.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
