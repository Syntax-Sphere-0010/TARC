import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ReadyToRaceHeader extends StatelessWidget {
  final bool isDark;
  final VoidCallback onOpenDrawer;
  final VoidCallback onNotificationTap;

  const ReadyToRaceHeader({
    super.key,
    required this.isDark,
    required this.onOpenDrawer,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 18, right: 18, top: 4),
      height: 154,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0xFFE2C8B0).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image: Home banner asset
            Image.asset(
              'assets/images/home_banner.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (ctx, err, stack) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFF6ED),
                        Color(0xFFFFDFBA),
                        Color(0xFFFFB37E),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Soft gradient overlay to keep text ultra-crisp and legible on the left
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      isDark
                          ? const Color(0xFF1E1813).withValues(alpha: 0.92)
                          : const Color(0xFFFFFDF9).withValues(alpha: 0.94),
                      isDark
                          ? const Color(0xFF1E1813).withValues(alpha: 0.75)
                          : const Color(0xFFFFFDF9).withValues(alpha: 0.70),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.52, 0.85],
                  ),
                ),
              ),
            ),

            // Top action buttons: Hamburger on left & Bell on right
            Positioned(
              top: 10,
              left: 12,
              child: GestureDetector(
                onTap: onOpenDrawer,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF28221D).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    color: isDark ? AppTheme.textDarkPrimary : const Color(0xFF2C221B),
                    size: 22,
                  ),
                ),
              ),
            ),

            Positioned(
              top: 10,
              right: 12,
              child: GestureDetector(
                onTap: onNotificationTap,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF28221D).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: AppTheme.primaryOrange,
                        size: 22,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE5572E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Left text block: "Ready to Race" + "Small steps everyday, lead to big dreams."
            Positioned(
              left: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Ready to\n',
                          style: GoogleFonts.caveat(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.white : const Color(0xFF251C15),
                            height: 0.95,
                          ),
                        ),
                        TextSpan(
                          text: 'Race',
                          style: GoogleFonts.caveat(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryOrange,
                            height: 0.95,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Small steps everyday,',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFC7B6A7) : const Color(0xFF5E4E42),
                    ),
                  ),
                  Text(
                    'lead to big dreams.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFC7B6A7) : const Color(0xFF5E4E42),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
