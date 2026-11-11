import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_state.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../widgets/scenic_illustrations.dart';
import '../widgets/interactive_modals.dart';
import '../widgets/user_avatar_widget.dart';
import '../widgets/supabase_status_sheet.dart';

class ProfileScreenTab extends StatelessWidget {
  final AppState appState;
  final VoidCallback onOpenDrawer;

  const ProfileScreenTab({
    super.key,
    required this.appState,
    required this.onOpenDrawer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = appState.isDarkMode;
    final user = appState.userProfile;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgCream,
      body: Stack(
        children: [
          // Botanical leaf in bottom right corner
          Positioned(
            right: 14,
            bottom: 30,
            child: BotanicalLeafSprig(
              size: 85,
              angle: -0.3,
              color: isDark ? const Color(0xFF5A4D40).withValues(alpha: 0.3) : null,
            ),
          ),

          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 750),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top Bar: Back arrow and Settings gear
                      _buildTopBar(context, isDark),

                      // 2. Profile Header (Avatar, Name, Tagline, Role badge, "Better Version of Me ♡")
                      _buildProfileHeader(context, user, isDark),

                      const SizedBox(height: 18),

                      // 3. 4 Stats Cards in a row (Total Classes, Completed, Day Streak, Goals Set)
                      _buildStatsRow(context, user, isDark),

                      const SizedBox(height: 20),

                      // 4. Menu / Settings Options Container
                      _buildMenuContainer(context, isDark),

                      const SizedBox(height: 22),

                      // 5. Handwritten quote: "Small steps every day ♡"
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Small steps',
                              style: GoogleFonts.caveat(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                color: isDark ? const Color(0xFFE5B58F) : const Color(0xFF6B5848),
                                height: 1.0,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'every day',
                                  style: GoogleFonts.caveat(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? const Color(0xFFE5B58F) : const Color(0xFF6B5848),
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '♡',
                                  style: GoogleFonts.caveat(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFE5B58F) : const Color(0xFF6B5848),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button -> jumps to Home tab
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              appState.setTabIndex(0);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF28221D) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: isDark ? AppTheme.textDarkPrimary : const Color(0xFF2C221B),
              ),
            ),
          ),

          // Edit profile icon
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryOrange),
                tooltip: 'Edit Profile',
                onPressed: () => InteractiveModals.showEditProfileSheet(context, appState),
              ),
              GestureDetector(
                onTap: onOpenDrawer,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF28221D) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: isDark ? AppTheme.textDarkPrimary : const Color(0xFF2C221B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile user, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      height: 155,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Scenic misty mountain background
          const Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(24)),
              child: ScenicProfileHeader(height: 155),
            ),
          ),

          // Right handwritten script: "Better Version of Me ♡"
          Positioned(
            right: 18,
            top: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Better',
                  style: GoogleFonts.caveat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF865538),
                    height: 1.0,
                  ),
                ),
                Text(
                  'Version of',
                  style: GoogleFonts.caveat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF865538),
                    height: 1.0,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Me ',
                      style: GoogleFonts.caveat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF865538),
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      '♡',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF865538),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Left Profile Avatar & Details
          Positioned(
            left: 14,
            top: 14,
            bottom: 14,
            child: Row(
              children: [
                // Avatar with border, edit badge, online indicator, tapping opens Avatar Picker
                UserAvatarWidget(
                  user: user,
                  size: 82,
                  borderWidth: 3.5,
                  borderColor: isDark ? AppTheme.cardDark : Colors.white,
                  showEditBadge: true,
                  isOnline: true,
                  onTap: () => InteractiveModals.showAvatarPickerSheet(context, appState),
                ),

                const SizedBox(width: 14),

                // Name, Motto & Role
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.text(isDark),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.motto,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSub(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.school_rounded,
                            size: 13,
                            color: AppTheme.primaryOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.role,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, UserProfile user, bool isDark) {
    // Dynamic real stats from app state
    final totalClasses = appState.classes.length;
    final completedCount = EventService.instance.completedEvents.length;
    final dayStreak = user.dayStreak;
    final goalsSet = appState.goals.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _buildStatCard(
            context: context,
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFFE86328),
            iconBg: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
            count: totalClasses.toString(),
            label: 'Total Subjects',
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            context: context,
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF4CAF50),
            iconBg: isDark ? const Color(0xFF1B3520) : const Color(0xFFE8F5E9),
            count: completedCount.toString(),
            label: 'Completed',
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            context: context,
            icon: Icons.calendar_today_rounded,
            iconColor: const Color(0xFF8E66DE),
            iconBg: isDark ? const Color(0xFF2B203E) : const Color(0xFFF2ECFF),
            count: dayStreak.toString(),
            label: 'Day Streak',
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            context: context,
            icon: Icons.star_border_rounded,
            iconColor: const Color(0xFFEAA200),
            iconBg: isDark ? const Color(0xFF382D12) : const Color(0xFFFFF7E0),
            count: goalsSet.toString(),
            label: 'Goals Set',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String count,
    required String label,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label: $count'),
              backgroundColor: iconColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadow(isDark),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.text(isDark),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSub(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuContainer(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppTheme.softShadow(isDark),
      ),
      child: Column(
        children: [
          // 0. Profile Photo & Cartoon Avatars
          _buildMenuItem(
            icon: Icons.face_retouching_natural_rounded,
            iconColor: AppTheme.primaryOrange,
            iconBg: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
            title: 'Profile Picture & Avatars',
            subtitle: 'Upload from Gallery or choose Cartoon Avatar',
            isDark: isDark,
            onTap: () => InteractiveModals.showAvatarPickerSheet(context, appState),
          ),
          Divider(height: 1, indent: 56, color: isDark ? AppTheme.borderDark : const Color(0xFFF3ECE4)),

          // 1. Personal Information
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF2196F3),
            iconBg: isDark ? const Color(0xFF142B3E) : const Color(0xFFE3F2FD),
            title: 'Personal Information',
            subtitle: '${appState.userProfile.email} • Tap to edit',
            isDark: isDark,
            onTap: () => InteractiveModals.showEditProfileSheet(context, appState),
          ),
          Divider(height: 1, indent: 56, color: isDark ? AppTheme.borderDark : const Color(0xFFF3ECE4)),

          // 2. My Goals
          _buildMenuItem(
            icon: Icons.track_changes_rounded,
            iconColor: const Color(0xFF4CAF50),
            iconBg: isDark ? const Color(0xFF1B3520) : const Color(0xFFE8F5E9),
            title: 'My Goals',
            subtitle: '${appState.goals.length} Goals Active',
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              appState.setTabIndex(2); // Jump to Goals Tab
            },
          ),
          Divider(height: 1, indent: 56, color: isDark ? AppTheme.borderDark : const Color(0xFFF3ECE4)),

          // 3. My Subjects & Schedule
          _buildMenuItem(
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF9C27B0),
            iconBg: isDark ? const Color(0xFF33193C) : const Color(0xFFF3E5F5),
            title: 'My Subjects & Classes',
            subtitle: '${appState.classes.length} Custom Subjects',
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              appState.setTabIndex(2);
            },
          ),
          Divider(height: 1, indent: 56, color: isDark ? AppTheme.borderDark : const Color(0xFFF3ECE4)),

          // 4. Notifications
          _buildMenuItem(
            icon: Icons.notifications_none_rounded,
            iconColor: const Color(0xFFFFA000),
            iconBg: isDark ? const Color(0xFF382A12) : const Color(0xFFFFF8E1),
            title: 'Notifications & Alerts',
            subtitle: 'Schedule alerts and reminders',
            isDark: isDark,
            onTap: () => InteractiveModals.showNotificationsSheet(context, appState),
          ),
          Divider(height: 1, indent: 56, color: isDark ? AppTheme.borderDark : const Color(0xFFF3ECE4)),

          // 5. Appearance (Dark / Light Theme)
          _buildMenuItem(
            icon: Icons.nightlight_round,
            iconColor: const Color(0xFF607D8B),
            iconBg: isDark ? const Color(0xFF263238) : const Color(0xFFECEFF1),
            title: 'Appearance',
            subtitle: isDark ? 'Dark mode enabled' : 'Warm cream light theme active',
            isDark: isDark,
            trailing: Switch(
              value: isDark,
              activeThumbColor: AppTheme.primaryOrange,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                appState.toggleDarkMode();
              },
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              appState.toggleDarkMode();
            },
          ),
          Divider(height: 1, indent: 56, color: isDark ? AppTheme.borderDark : const Color(0xFFF3ECE4)),

          // 6. Supabase Cloud Sync
          _buildMenuItem(
            icon: Icons.cloud_sync_rounded,
            iconColor: const Color(0xFF3ECF8E),
            iconBg: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F5E9),
            title: 'Supabase Cloud Sync',
            subtitle: 'Real-time database • Test connection & sync',
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              SupabaseStatusSheet.show(context, appState);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool isDark,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppTheme.textSub(isDark),
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? AppTheme.textDarkSecondary : const Color(0xFFC7BBB0),
                ),
          ],
        ),
      ),
    );
  }
}
