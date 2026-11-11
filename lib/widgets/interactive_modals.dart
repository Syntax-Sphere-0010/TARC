import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_state.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../utils/date_time_utils.dart';
import '../theme/app_theme.dart';
import 'schedule_alert_popup.dart';
import 'user_avatar_widget.dart';

class InteractiveModals {
  /// Master creation bottom sheet for Classes, Reminders, and Goals
  static void showCreateItemSheet(
    BuildContext context,
    AppState appState, {
    int initialCategory = 0, // 0: Class, 1: Reminder, 2: Goal
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateItemModal(
        appState: appState,
        initialCategory: initialCategory,
      ),
    );
  }

  /// Routine sheets for the 8 home categories (Sun, Moon, Coffee, etc.)
  static void showRoutineSheet(BuildContext context, String name, [bool isDark = false]) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _RoutineDetailModal(routineName: name, isDark: isDark),
    );
  }

  /// Notifications modal for bell icon
  static void showNotificationsSheet(BuildContext context, AppState appState) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationsModal(appState: appState),
    );
  }

  /// Class details & management
  static void showClassDetailSheet(
    BuildContext context,
    ClassItem item,
    AppState appState,
  ) {
    HapticFeedback.lightImpact();
    final isDark = appState.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF4A4036) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? item.iconColor.withValues(alpha: 0.18) : item.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.text(isDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.timeRange} • ${item.room}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSub(isDark),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A241F) : const Color(0xFFF9F6F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_pin_circle_outlined,
                          size: 18, color: AppTheme.primaryOrange),
                      const SizedBox(width: 8),
                      Text(
                        'Instructor: ${item.instructor}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text(isDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.notes_rounded,
                          size: 18, color: AppTheme.primaryOrange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.notes,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppTheme.textSub(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      appState.removeClass(item.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed ${item.title}'),
                          backgroundColor: Colors.red.shade400,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete Class'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Attendance marked for ${item.title}!'),
                          backgroundColor: AppTheme.primaryOrange,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      'Mark Present',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5572E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScheduleAlertPopup.showTriggerChooser(
                    context,
                    title: item.title,
                    time: item.timeRange,
                    location: item.room,
                    isDark: isDark,
                  );
                },
                icon: const Icon(Icons.alarm_on_rounded, size: 18),
                label: const Text(
                  '🚨 Trigger Schedule Alert Pop-up',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reminder action sheet for 3-dots
  static void showReminderOptions(
    BuildContext context,
    ReminderItem item,
    AppState appState,
  ) {
    HapticFeedback.lightImpact();
    final isDark = appState.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF4A4036) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.text(isDark),
              ),
            ),
            Text(
              'Scheduled for ${item.time}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSub(isDark),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                item.isCompleted ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                color: AppTheme.primaryOrange,
              ),
              title: Text(
                item.isCompleted ? 'Mark as Incomplete' : 'Mark as Completed',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.text(isDark),
                ),
              ),
              onTap: () {
                appState.toggleReminderCompletion(item.id);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Delete Reminder', style: TextStyle(color: Colors.red)),
              onTap: () {
                appState.removeReminder(item.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reminder deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Direct avatar picker: Upload from Gallery or select Cartoon profile
  static void showAvatarPickerSheet(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final user = appState.userProfile;
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF4A4036) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Picture',
                            style: GoogleFonts.inter(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.text(isDark),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Upload from gallery or pick a cartoon avatar',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSub(isDark),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Avatar Live Preview
                  Center(
                    child: UserAvatarWidget(
                      user: user,
                      size: 96,
                      borderWidth: 3.5,
                      borderColor: AppTheme.primaryOrange,
                      isOnline: true,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Action Buttons: Gallery & Camera
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.photo_library_rounded, size: 20),
                          label: const Text(
                            'Upload Gallery',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            try {
                              final XFile? file = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1200,
                                maxHeight: 1200,
                                imageQuality: 88,
                              );
                              if (file != null) {
                                appState.updateProfile(avatarPath: file.path);
                                setModalState(() {});
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile photo uploaded from gallery! 📸'),
                                      backgroundColor: AppTheme.primaryOrange,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint('Error picking from gallery: $e');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.text(isDark),
                            side: BorderSide(
                              color: isDark ? AppTheme.borderDark : const Color(0xFFDCC8B8),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt_rounded, size: 19, color: AppTheme.primaryOrange),
                          label: const Text(
                            'Camera',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            try {
                              final XFile? file = await picker.pickImage(
                                source: ImageSource.camera,
                                maxWidth: 1200,
                                maxHeight: 1200,
                                imageQuality: 88,
                              );
                              if (file != null) {
                                appState.updateProfile(avatarPath: file.path);
                                setModalState(() {});
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile photo captured! 📸'),
                                      backgroundColor: AppTheme.primaryOrange,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint('Error capturing photo: $e');
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Section: Cartoon Profiles
                  Row(
                    children: [
                      const Icon(Icons.face_retouching_natural_rounded, size: 18, color: AppTheme.primaryOrange),
                      const SizedBox(width: 8),
                      Text(
                        'Cartoon Profiles',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.text(isDark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '8 Avatars',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Cartoon Profiles Horizontal List
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: CartoonAvatarList.items.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 12),
                      itemBuilder: (c, idx) {
                        final cartoon = CartoonAvatarList.items[idx];
                        final isSel = (user.avatarPath == cartoon.assetPath && cartoon.assetPath != null) ||
                            ((user.avatarPath == null || user.avatarPath!.isEmpty) && user.avatarPreset == cartoon.presetId);

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            appState.updateProfile(
                              avatarPreset: cartoon.presetId,
                              avatarPath: cartoon.assetPath ?? '',
                            );
                            setModalState(() {});
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 66,
                                    height: 66,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSel ? AppTheme.primaryOrange : (isDark ? AppTheme.borderDark : const Color(0xFFE8DACB)),
                                        width: isSel ? 3.0 : 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: ClipOval(
                                      child: cartoon.assetPath != null
                                          ? Image.asset(
                                              cartoon.assetPath!,
                                              width: 62,
                                              height: 62,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [cartoon.gradientStart, cartoon.gradientEnd],
                                                ),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  cartoon.fallbackIcon ?? Icons.face_rounded,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (isSel)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryOrange,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, color: Colors.white, size: 13),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cartoon.name,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                  color: isSel ? AppTheme.primaryOrange : AppTheme.text(isDark),
                                ),
                              ),
                              Text(
                                cartoon.title,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppTheme.textSub(isDark),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Section: Classic Avatars
                  Text(
                    'Classic Icons',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSub(isDark),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildClassicPill(appState, 0, 'Sunrise', Icons.landscape_rounded, isDark, setModalState),
                        _buildClassicPill(appState, 1, 'Scholar', Icons.school_rounded, isDark, setModalState),
                        _buildClassicPill(appState, 2, 'Champion', Icons.auto_awesome_rounded, isDark, setModalState),
                        _buildClassicPill(appState, 3, 'Athlete', Icons.directions_run_rounded, isDark, setModalState),
                        _buildClassicPill(appState, 4, 'Zen Mind', Icons.self_improvement_rounded, isDark, setModalState),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Apply / Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Apply Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildClassicPill(AppState appState, int preset, String label, IconData icon, bool isDark, StateSetter setModalState) {
    final user = appState.userProfile;
    final isSel = (user.avatarPath == null || user.avatarPath!.isEmpty) && user.avatarPreset == preset;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        appState.updateProfile(avatarPreset: preset, avatarPath: '');
        setModalState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppTheme.primaryOrange : (isDark ? const Color(0xFF2E241E) : const Color(0xFFF7EFE7)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel ? AppTheme.primaryOrange : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSel ? Colors.white : AppTheme.primaryOrange),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSel ? Colors.white : AppTheme.text(isDark),
                fontSize: 12,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Profile information editor
  static void showEditProfileSheet(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    final picker = ImagePicker();
    final nameCtrl = TextEditingController(text: appState.userProfile.name);
    final mottoCtrl = TextEditingController(text: appState.userProfile.motto);
    final roleCtrl = TextEditingController(text: appState.userProfile.role);
    final emailCtrl = TextEditingController(text: appState.userProfile.email);
    final phoneCtrl = TextEditingController(text: appState.userProfile.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final user = appState.userProfile;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF4A4036) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Personal Information & Profile',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Update your profile photo, cartoon avatar, and personal details.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSub(isDark),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Top Avatar with quick actions
                    Row(
                      children: [
                        UserAvatarWidget(
                          user: user,
                          size: 72,
                          borderWidth: 2.5,
                          borderColor: AppTheme.primaryOrange,
                          showEditBadge: true,
                          onTap: () async {
                            Navigator.pop(ctx);
                            showAvatarPickerSheet(context, appState);
                          },
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.photo_library_rounded, size: 16),
                                label: const Text('Upload Photo', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  try {
                                    final XFile? file = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 1200,
                                      maxHeight: 1200,
                                      imageQuality: 88,
                                    );
                                    if (file != null) {
                                      appState.updateProfile(avatarPath: file.path);
                                      setModalState(() {});
                                    }
                                  } catch (e) {
                                    debugPrint('Error: $e');
                                  }
                                },
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.text(isDark),
                                  side: BorderSide(color: isDark ? AppTheme.borderDark : const Color(0xFFDCC8B8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.face_retouching_natural_rounded, size: 16, color: AppTheme.primaryOrange),
                                label: const Text('Cartoon Avatars', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  showAvatarPickerSheet(context, appState);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Quick Cartoon Selector Row
                    Text(
                      'Quick Cartoon Profiles',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text(isDark),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: CartoonAvatarList.items.map((cartoon) {
                          final isSel = (user.avatarPath == cartoon.assetPath && cartoon.assetPath != null) ||
                              ((user.avatarPath == null || user.avatarPath!.isEmpty) && user.avatarPreset == cartoon.presetId);
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              appState.updateProfile(
                                avatarPreset: cartoon.presetId,
                                avatarPath: cartoon.assetPath ?? '',
                              );
                              setModalState(() {});
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSel ? AppTheme.primaryOrange : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: ClipOval(
                                child: cartoon.assetPath != null
                                    ? Image.asset(cartoon.assetPath!, width: 44, height: 44, fit: BoxFit.cover)
                                    : Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [cartoon.gradientStart, cartoon.gradientEnd]),
                                        ),
                                        child: Center(
                                          child: Icon(cartoon.fallbackIcon ?? Icons.face_rounded, color: Colors.white, size: 22),
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 18),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: AppTheme.text(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(color: AppTheme.textSub(isDark)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSub(isDark)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: roleCtrl,
                      style: TextStyle(color: AppTheme.text(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Role / Designation',
                        hintText: 'e.g. Computer Science Student',
                        labelStyle: TextStyle(color: AppTheme.textSub(isDark)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.school_outlined, color: AppTheme.textSub(isDark)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: mottoCtrl,
                      style: TextStyle(color: AppTheme.text(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Personal Motto / Bio',
                        hintText: 'e.g. Dream • Plan • Do',
                        labelStyle: TextStyle(color: AppTheme.textSub(isDark)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.format_quote_outlined, color: AppTheme.textSub(isDark)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      style: TextStyle(color: AppTheme.text(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(color: AppTheme.textSub(isDark)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSub(isDark)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      style: TextStyle(color: AppTheme.text(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(color: AppTheme.textSub(isDark)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textSub(isDark)),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          appState.updateProfile(
                            name: nameCtrl.text.trim(),
                            role: roleCtrl.text.trim(),
                            motto: mottoCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile details saved successfully! ✨'),
                              backgroundColor: AppTheme.primaryOrange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text(
                          'Save Details',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CreateItemModal extends StatefulWidget {
  final AppState appState;
  final int initialCategory;

  const _CreateItemModal({
    required this.appState,
    required this.initialCategory,
  });

  @override
  State<_CreateItemModal> createState() => _CreateItemModalState();
}

class _CreateItemModalState extends State<_CreateItemModal> {
  late int _selectedType;

  // Fields for Class
  final _classTitleCtrl = TextEditingController();
  final _classRoomCtrl = TextEditingController(text: 'Room 204');
  TimeOfDay _classStart = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _classEnd = const TimeOfDay(hour: 11, minute: 0);
  int _colorIndex = 0;

  // Fields for Reminder
  final _reminderTitleCtrl = TextEditingController();
  TimeOfDay _reminderTime = const TimeOfDay(hour: 14, minute: 30);
  PriorityLevel _priority = PriorityLevel.medium;

  // Fields for Goal
  final _goalTitleCtrl = TextEditingController();
  final _goalSubtitleCtrl = TextEditingController(text: 'Learn • Practice • Grow');
  double _goalProgress = 0.50;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF4A4036) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Category Selector Tabs
              Row(
                children: [
                  _buildTypeTab(0, 'Class', Icons.school_rounded, isDark),
                  const SizedBox(width: 8),
                  _buildTypeTab(1, 'Reminder', Icons.alarm_rounded, isDark),
                  const SizedBox(width: 8),
                  _buildTypeTab(2, 'Goal', Icons.flag_rounded, isDark),
                ],
              ),
              const SizedBox(height: 20),
              if (_selectedType == 0) _buildClassForm(isDark),
              if (_selectedType == 1) _buildReminderForm(isDark),
              if (_selectedType == 2) _buildGoalForm(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab(int index, String label, IconData icon, bool isDark) {
    final isSelected = _selectedType == index;
    final unselectedBg = isDark ? const Color(0xFF2E2721) : const Color(0xFFF6F2EC);
    final unselectedText = isDark ? AppTheme.textDarkSecondary : AppTheme.textMuted;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryOrange : unselectedBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : unselectedText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : unselectedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add New Class',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.text(isDark),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _classTitleCtrl,
          autofocus: true,
          style: TextStyle(color: AppTheme.text(isDark)),
          decoration: InputDecoration(
            hintText: 'e.g. Data Structures, Strategic Marketing',
            hintStyle: TextStyle(color: isDark ? const Color(0xFF6E6256) : null),
            labelText: 'Class Name',
            labelStyle: TextStyle(color: AppTheme.textSub(isDark)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _classRoomCtrl,
          style: TextStyle(color: AppTheme.text(isDark)),
          decoration: InputDecoration(
            hintText: 'e.g. Room 204, Lecture Hall B',
            hintStyle: TextStyle(color: isDark ? const Color(0xFF6E6256) : null),
            labelText: 'Location / Room',
            labelStyle: TextStyle(color: AppTheme.textSub(isDark)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: AppTheme.text(isDark),
                  side: BorderSide(color: isDark ? AppTheme.borderDark : const Color(0xFFD6C8B8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _classStart,
                  );
                  if (picked != null) setState(() => _classStart = picked);
                },
                icon: const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.primaryOrange),
                label: Text('Start: ${_classStart.format(context)}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: AppTheme.text(isDark),
                  side: BorderSide(color: isDark ? AppTheme.borderDark : const Color(0xFFD6C8B8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _classEnd,
                  );
                  if (picked != null) setState(() => _classEnd = picked);
                },
                icon: const Icon(Icons.access_time_filled_rounded, size: 16, color: AppTheme.primaryOrange),
                label: Text('End: ${_classEnd.format(context)}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Card Color Theme', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.text(isDark))),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildColorOption(0, 'Warm Peach', const Color(0xFFFFF6ED), AppTheme.primaryOrange, isDark),
            const SizedBox(width: 8),
            _buildColorOption(1, 'Lavender', const Color(0xFFF7F2FF), const Color(0xFF7E57C2), isDark),
            const SizedBox(width: 8),
            _buildColorOption(2, 'Mint Green', const Color(0xFFF0F9F3), const Color(0xFF43A047), isDark),
          ],
        ),
        const SizedBox(height: 20),
        _buildSubmitButton(
          title: 'Save Class',
          onTap: () {
            if (_classTitleCtrl.text.trim().isEmpty) return;
            final colors = [
              [const Color(0xFFFFF6ED), AppTheme.primaryOrange, const Color(0xFFFFECE0), Icons.menu_book_rounded],
              [const Color(0xFFF7F2FF), const Color(0xFF7E57C2), const Color(0xFFEDE7F6), Icons.bar_chart_rounded],
              [const Color(0xFFF0F9F3), const Color(0xFF43A047), const Color(0xFFE8F5E9), Icons.groups_rounded],
            ][_colorIndex];

            widget.appState.addClass(
              ClassItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: _classTitleCtrl.text.trim(),
                timeRange: '${_classStart.format(context)} – ${_classEnd.format(context)}',
                room: _classRoomCtrl.text.trim(),
                cardBg: colors[0] as Color,
                iconColor: colors[1] as Color,
                iconBg: colors[2] as Color,
                icon: colors[3] as IconData,
              ),
            );
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added class "${_classTitleCtrl.text.trim()}"!'),
                backgroundColor: AppTheme.primaryOrange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildColorOption(int index, String label, Color bg, Color border, bool isDark) {
    final isSel = _colorIndex == index;
    final displayBg = isDark ? const Color(0xFF2A231D) : bg;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _colorIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: displayBg,
            border: Border.all(
              color: isSel ? border : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                color: border,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add New Reminder',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.text(isDark),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reminderTitleCtrl,
          autofocus: true,
          style: TextStyle(color: AppTheme.text(isDark)),
          decoration: InputDecoration(
            hintText: 'e.g. Complete Assignment 2, Group Call',
            hintStyle: TextStyle(color: isDark ? const Color(0xFF6E6256) : null),
            labelText: 'Reminder Title',
            labelStyle: TextStyle(color: AppTheme.textSub(isDark)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: AppTheme.text(isDark),
                  side: BorderSide(color: isDark ? AppTheme.borderDark : const Color(0xFFD6C8B8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime,
                  );
                  if (picked != null) setState(() => _reminderTime = picked);
                },
                icon: const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.primaryOrange),
                label: Text('Time: ${_reminderTime.format(context)}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('Priority Level', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.text(isDark))),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPriorityOption(PriorityLevel.high, 'High', AppTheme.highBadgeBg, AppTheme.highBadgeText, isDark),
            const SizedBox(width: 8),
            _buildPriorityOption(PriorityLevel.medium, 'Medium', AppTheme.mediumBadgeBg, AppTheme.mediumBadgeText, isDark),
            const SizedBox(width: 8),
            _buildPriorityOption(PriorityLevel.low, 'Low', AppTheme.lowBadgeBg, AppTheme.lowBadgeText, isDark),
          ],
        ),
        const SizedBox(height: 20),
        _buildSubmitButton(
          title: 'Save Reminder',
          onTap: () async {
            final title = _reminderTitleCtrl.text.trim();
            if (title.isEmpty) return;
            final now = DateTime.now();
            final eventDate = widget.appState.selectedDate;
            final reminderDt = DateTimeUtils.combineDateAndTime(eventDate, _reminderTime);
            final timeStr = _reminderTime.format(context);

            final eventReminder = EventReminder(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: title,
              date: eventDate,
              time: timeStr,
              reminderDateTime: reminderDt,
              notificationId: DateTimeUtils.generateNotificationId(),
              createdAt: now,
              updatedAt: now,
              priority: _priority.name,
            );
            await EventService.instance.addEvent(eventReminder);

            widget.appState.addReminder(
              ReminderItem(
                id: eventReminder.id,
                title: title,
                time: timeStr,
                priority: _priority,
                icon: Icons.checklist_rounded,
                iconColor: AppTheme.primaryOrange,
                iconBg: AppTheme.primaryOrangeLight,
                date: eventDate,
              ),
            );
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added reminder "$title"!'),
                  backgroundColor: AppTheme.primaryOrange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPriorityOption(PriorityLevel p, String label, Color bg, Color text, bool isDark) {
    final isSel = _priority == p;
    final displayBg = isDark ? text.withValues(alpha: 0.15) : bg;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = p),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: displayBg,
            border: Border.all(
              color: isSel ? text : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                color: text,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add New Goal',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.text(isDark),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _goalTitleCtrl,
          autofocus: true,
          style: TextStyle(color: AppTheme.text(isDark)),
          decoration: InputDecoration(
            hintText: 'e.g. Master Financial Modelling',
            hintStyle: TextStyle(color: isDark ? const Color(0xFF6E6256) : null),
            labelText: 'Goal Title',
            labelStyle: TextStyle(color: AppTheme.textSub(isDark)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _goalSubtitleCtrl,
          style: TextStyle(color: AppTheme.text(isDark)),
          decoration: InputDecoration(
            hintText: 'e.g. Read • Model • Execute',
            hintStyle: TextStyle(color: isDark ? const Color(0xFF6E6256) : null),
            labelText: 'Motto / Steps',
            labelStyle: TextStyle(color: AppTheme.textSub(isDark)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Starting Progress', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.text(isDark))),
            Text('${(_goalProgress * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryOrange)),
          ],
        ),
        Slider(
          value: _goalProgress,
          activeColor: AppTheme.primaryOrange,
          inactiveColor: isDark ? const Color(0xFF38312B) : const Color(0xFFF1E9E0),
          onChanged: (v) => setState(() => _goalProgress = v),
        ),
        const SizedBox(height: 16),
        _buildSubmitButton(
          title: 'Create Goal',
          onTap: () {
            if (_goalTitleCtrl.text.trim().isEmpty) return;
            widget.appState.addGoal(
              GoalItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: _goalTitleCtrl.text.trim(),
                subtitle: _goalSubtitleCtrl.text.trim(),
                progress: _goalProgress,
                category: 'Personal',
              ),
            );
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Created goal "${_goalTitleCtrl.text.trim()}"!'),
                backgroundColor: AppTheme.primaryOrange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton({required String title, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryOrange,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _RoutineDetailModal extends StatelessWidget {
  final String routineName;
  final bool isDark;

  const _RoutineDetailModal({required this.routineName, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final routineDetails = {
      'Sun': {
        'title': 'Morning Sun Routine',
        'desc': 'Start your morning with mindfulness and intentionality.',
        'icon': Icons.wb_sunny_rounded,
        'color': AppTheme.primaryOrange,
        'steps': ['Drink 500ml warm water', '10 mins sunlight & breathwork', 'Review today’s 3 major priorities'],
      },
      'Moon': {
        'title': 'Evening Moon Wind-down',
        'desc': 'Disconnect from screens and prepare for deep restorative sleep.',
        'icon': Icons.nightlight_round,
        'color': const Color(0xFF9E8ED2),
        'steps': ['Turn off blue light screens', '15 mins reading or journaling', 'Set clothes & books for tomorrow'],
      },
      'Coffee': {
        'title': 'Coffee & Focus Sprint',
        'desc': '25-minute Pomodoro deep focus session with coffee break.',
        'icon': Icons.coffee_rounded,
        'color': const Color(0xFFFFB280),
        'steps': ['Single-task focus: 25 mins', 'Short 5 min stretch', 'Hydrate and log completed milestone'],
      },
      'Study': {
        'title': 'Study Mode Active',
        'desc': 'Deep immersive revision and active recall practice.',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF66BB6A),
        'steps': ['Review lecture notes', 'Solve 5 practice problems', 'Summarize key takeaways in flashcards'],
      },
      'Evening': {
        'title': 'Sunset Reflections',
        'desc': 'Celebrate today’s accomplishments and clear pending thoughts.',
        'icon': Icons.wb_twilight_rounded,
        'color': AppTheme.primaryOrange,
        'steps': ['Check off completed reminders', 'Write down 1 gratitude thought', 'Plan dinner & relaxed walk'],
      },
      'Next Week': {
        'title': 'Next Week Horizons',
        'desc': 'Look ahead to upcoming tests, submissions, and goals.',
        'icon': Icons.calendar_month_outlined,
        'color': const Color(0xFF5C6BC0),
        'steps': ['August 11-17: Mid-semester review', 'Case study submission deadline', 'Team presentation rehearsal'],
      },
      'Custom': {
        'title': 'Custom Routine',
        'desc': 'Configure your personal habit loops and reminders.',
        'icon': Icons.settings_rounded,
        'color': const Color(0xFFFFB280),
        'steps': ['Add custom alarms', 'Sync with Google Calendar', 'Set custom vibration intervals'],
      },
      'More': {
        'title': 'Quick Actions & More',
        'desc': 'Export timetable, track statistics, and manage backups.',
        'icon': Icons.more_horiz_rounded,
        'color': const Color(0xFF78909C),
        'steps': ['Export daily schedule as PDF', 'Backup data to Cloud', 'Share progress with study partner'],
      },
    }[routineName] ?? {
      'title': routineName,
      'desc': 'Routine details and tracking',
      'icon': Icons.check_circle_outline,
      'color': AppTheme.primaryOrange,
      'steps': ['Step 1: Focus', 'Step 2: Act', 'Step 3: Review'],
    };

    final steps = routineDetails['steps'] as List<String>;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF4A4036) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (routineDetails['color'] as Color).withValues(alpha: isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  routineDetails['icon'] as IconData,
                  color: routineDetails['color'] as Color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routineDetails['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text(isDark),
                      ),
                    ),
                    Text(
                      routineDetails['desc'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppTheme.textSub(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.primaryOrange, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.text(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Activated ${routineDetails['title']}!'),
                    backgroundColor: AppTheme.primaryOrange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Start Routine Now',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsModal extends StatelessWidget {
  final AppState appState;

  const _NotificationsModal({required this.appState});

  @override
  Widget build(BuildContext context) {
    final isDark = appState.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF4A4036) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text(isDark),
                ),
              ),
              Text(
                '3 New',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...appState.notifications.map((n) {
            final isUnread = n['unread'] as bool;
            Color itemBg;
            if (isDark) {
              itemBg = isUnread ? const Color(0xFF382317) : const Color(0xFF2A241F);
            } else {
              itemBg = isUnread ? const Color(0xFFFFF6ED) : const Color(0xFFF9F9F9);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: itemBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUnread ? AppTheme.primaryOrange.withValues(alpha: 0.3) : Colors.transparent,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryOrange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n['title'] as String,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppTheme.text(isDark),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          n['message'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSub(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    n['time'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: AppTheme.textHint(isDark),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryOrange,
                side: const BorderSide(color: AppTheme.primaryOrange, width: 1.3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScheduleAlertPopup.showTriggerChooser(
                  context,
                  title: 'Management Accounting',
                  time: '10:00 AM – 11:00 AM',
                  location: 'Room 203',
                  isDark: isDark,
                );
              },
              icon: const Icon(Icons.alarm_on_rounded, size: 18),
              label: const Text(
                '🚨 Test Schedule Begin Pop-up',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
