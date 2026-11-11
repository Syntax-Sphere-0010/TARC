import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class CustomAppBottomBar extends StatelessWidget {
  final AppState appState;
  final VoidCallback onAddPressed;

  const CustomAppBottomBar({
    super.key,
    required this.appState,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = appState.isDarkMode;
    final bgColor = isDark ? AppTheme.cardDark : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                isHomeSpecial: true,
              ),
              _buildNavItem(
                index: 1,
                label: 'Calendar',
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_month_rounded,
              ),
              _buildCenterAddButton(),
              _buildNavItem(
                index: 2,
                label: 'Goals',
                icon: Icons.track_changes_outlined,
                activeIcon: Icons.track_changes_rounded,
              ),
              _buildNavItem(
                index: 3,
                label: 'Profile',
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAddButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onAddPressed();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF7E3E),
              AppTheme.primaryOrange,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryOrange.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    bool isHomeSpecial = false,
  }) {
    final isSelected = appState.currentTabIndex == index;
    final isDark = appState.isDarkMode;
    final unselectedColor = isDark ? const Color(0xFFAFA49A) : const Color(0xFF8C7E72);
    final color = isSelected ? AppTheme.primaryOrange : unselectedColor;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        appState.setTabIndex(index);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isHomeSpecial && isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              )
            else
              Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: 22,
              ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            // Bottom indicator line when selected (as seen in Image 2, 3, 4)
            Container(
              height: 2.2,
              width: 22,
              decoration: BoxDecoration(
                color: isSelected && !(isHomeSpecial && index == 0)
                    ? AppTheme.primaryOrange
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
