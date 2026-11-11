import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary brand orange
  static const Color primaryOrange = Color(0xFFE86328);
  static const Color primaryOrangeLight = Color(0xFFFFECE0);
  static const Color primaryOrangeDark = Color(0xFFC74E18);

  // Background tints
  static const Color bgCream = Color(0xFFFBF7F2);
  static const Color cardWhite = Colors.white;

  // Dark mode colors
  static const Color bgDark = Color(0xFF141210);
  static const Color cardDark = Color(0xFF221E1A);
  static const Color cardDarkElevated = Color(0xFF2A2520);
  static const Color textDarkPrimary = Color(0xFFFBF6F0);
  static const Color textDarkSecondary = Color(0xFFC8BDB2);
  static const Color textDarkMuted = Color(0xFFA4988C);
  static const Color borderDark = Color(0xFF38312B);

  // Light mode text colors
  static const Color textMain = Color(0xFF241C15);
  static const Color textMuted = Color(0xFF7E7368);
  static const Color textLight = Color(0xFFA09489);

  // Dynamic Theme Resolvers
  static Color text(bool isDark) => isDark ? textDarkPrimary : textMain;
  static Color textSub(bool isDark) => isDark ? textDarkSecondary : textMuted;
  static Color textHint(bool isDark) => isDark ? textDarkMuted : textLight;
  static Color cardBg(bool isDark) => isDark ? cardDark : cardWhite;
  static Color cardElevated(bool isDark) => isDark ? cardDarkElevated : const Color(0xFFFFF8F2);
  static Color border(bool isDark) => isDark ? borderDark : const Color(0xFFF3E7DC);
  static Color icon(bool isDark) => isDark ? textDarkPrimary : const Color(0xFF2C221B);

  // Priority Badges
  static const Color highBadgeBg = Color(0xFFFFEAE6);
  static const Color highBadgeText = Color(0xFFDE4536);

  static const Color mediumBadgeBg = Color(0xFFFEF2DB);
  static const Color mediumBadgeText = Color(0xFFCC7715);

  static const Color lowBadgeBg = Color(0xFFE6F7EB);
  static const Color lowBadgeText = Color(0xFF2E8B57);

  // Dark mode priority badge backgrounds
  static const Color highBadgeBgDark = Color(0xFF3E1C18);
  static const Color mediumBadgeBgDark = Color(0xFF3E2D15);
  static const Color lowBadgeBgDark = Color(0xFF173822);

  // Card tints for classes
  static const Color classPeach = Color(0xFFFFF6ED);
  static const Color classPurple = Color(0xFFF6F2FF);
  static const Color classGreen = Color(0xFFF1FAF3);

  static const Color classPeachDark = Color(0xFF2E2219);
  static const Color classPurpleDark = Color(0xFF261D33);
  static const Color classGreenDark = Color(0xFF192A1D);

  // Soft shadows
  static List<BoxShadow> softShadow([bool isDark = false]) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.35)
              : const Color(0xFFD6C8B8).withValues(alpha: 0.18),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.2)
              : const Color(0xFF8A6A4B).withValues(alpha: 0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryOrange.withValues(alpha: 0.35),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];

  // Fonts
  static TextStyle scriptHeader({
    double fontSize = 42,
    required bool isDark,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return GoogleFonts.caveat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: text(isDark),
      letterSpacing: 0.5,
      height: 1.05,
    );
  }

  static TextStyle handQuote({
    double fontSize = 18,
    required bool isDark,
    FontWeight fontWeight = FontWeight.w600,
    FontStyle fontStyle = FontStyle.italic,
  }) {
    return GoogleFonts.caveat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: isDark ? const Color(0xFFE5B58F) : const Color(0xFF865538),
      height: 1.2,
    );
  }

  static TextStyle heading({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    required bool isDark,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: text(isDark),
      letterSpacing: -0.2,
    );
  }

  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    required bool isDark,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: textSub(isDark),
    );
  }
}
