import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

/// Cartoon profile preset definition
class CartoonAvatarItem {
  final int presetId;
  final String name;
  final String title;
  final String? assetPath;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData? fallbackIcon;

  const CartoonAvatarItem({
    required this.presetId,
    required this.name,
    required this.title,
    this.assetPath,
    required this.gradientStart,
    required this.gradientEnd,
    this.fallbackIcon,
  });
}

class CartoonAvatarList {
  static const List<CartoonAvatarItem> items = [
    CartoonAvatarItem(
      presetId: 101,
      name: 'Leo',
      title: 'Hero Boy',
      assetPath: 'assets/images/cartoon_avatar_1.jpg',
      gradientStart: Color(0xFFFF9966),
      gradientEnd: Color(0xFFFF5E62),
    ),
    CartoonAvatarItem(
      presetId: 102,
      name: 'Mia',
      title: 'Scholar Girl',
      assetPath: 'assets/images/cartoon_avatar_2.jpg',
      gradientStart: Color(0xFFF093FB),
      gradientEnd: Color(0xFFF5576C),
    ),
    CartoonAvatarItem(
      presetId: 103,
      name: 'Alex',
      title: 'Vibe Kid',
      assetPath: 'assets/images/cartoon_avatar_3.jpg',
      gradientStart: Color(0xFF4FACFE),
      gradientEnd: Color(0xFF00F2FE),
    ),
    CartoonAvatarItem(
      presetId: 104,
      name: 'Pixel',
      title: 'Gamer Star',
      gradientStart: Color(0xFF8A2387),
      gradientEnd: Color(0xFFE94057),
      fallbackIcon: Icons.sports_esports_rounded,
    ),
    CartoonAvatarItem(
      presetId: 105,
      name: 'Mochi',
      title: 'Cute Kitty',
      gradientStart: Color(0xFFFF9A8B),
      gradientEnd: Color(0xFFFF6A88),
      fallbackIcon: Icons.pets_rounded,
    ),
    CartoonAvatarItem(
      presetId: 106,
      name: 'Astro',
      title: 'Star Cadet',
      gradientStart: Color(0xFF141E30),
      gradientEnd: Color(0xFF243B55),
      fallbackIcon: Icons.rocket_launch_rounded,
    ),
    CartoonAvatarItem(
      presetId: 107,
      name: 'Cipher',
      title: 'Code Ninja',
      gradientStart: Color(0xFF11998E),
      gradientEnd: Color(0xFF38EF7D),
      fallbackIcon: Icons.terminal_rounded,
    ),
    CartoonAvatarItem(
      presetId: 108,
      name: 'Lotus',
      title: 'Zen Mind',
      gradientStart: Color(0xFFFFB300),
      gradientEnd: Color(0xFFE65100),
      fallbackIcon: Icons.self_improvement_rounded,
    ),
  ];
}

/// Unified Avatar Widget supporting Gallery Uploads, Cartoon Profiles, and Classic presets
class UserAvatarWidget extends StatelessWidget {
  final UserProfile user;
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final bool showEditBadge;
  final bool isOnline;
  final VoidCallback? onTap;

  const UserAvatarWidget({
    super.key,
    required this.user,
    this.size = 80,
    this.borderWidth = 3.0,
    this.borderColor,
    this.showEditBadge = false,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? Colors.white;

    Widget avatarCore = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: _buildAvatarImage(context),
      ),
    );

    if (!showEditBadge && !isOnline) {
      if (onTap != null) {
        return GestureDetector(
          onTap: onTap,
          child: avatarCore,
        );
      }
      return avatarCore;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatarCore,

          // Online indicator dot
          if (isOnline)
            Positioned(
              right: size * 0.04,
              bottom: size * 0.04,
              child: Container(
                width: size * 0.22,
                height: size * 0.22,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: effectiveBorderColor,
                    width: 2.5,
                  ),
                ),
              ),
            ),

          // Camera / Edit Badge
          if (showEditBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: EdgeInsets.all(size * 0.08),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: size * 0.22,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(BuildContext context) {
    // 1. Check if user selected an image file from gallery or an asset path
    if (user.avatarPath != null && user.avatarPath!.isNotEmpty) {
      final path = user.avatarPath!;
      if (path.startsWith('assets/')) {
        return Image.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _buildPresetAvatar(context, user.avatarPreset),
        );
      } else {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => _buildPresetAvatar(context, user.avatarPreset),
          );
        }
      }
    }

    // 2. Cartoon or Preset avatar
    return _buildPresetAvatar(context, user.avatarPreset);
  }

  Widget _buildPresetAvatar(BuildContext context, int preset) {
    // Check cartoon presets (101 - 108)
    if (preset >= 101 && preset <= 108) {
      final cartoon = CartoonAvatarList.items.firstWhere(
        (c) => c.presetId == preset,
        orElse: () => CartoonAvatarList.items.first,
      );

      if (cartoon.assetPath != null) {
        return Image.asset(
          cartoon.assetPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _buildIllustratedCartoon(cartoon),
        );
      } else {
        return _buildIllustratedCartoon(cartoon);
      }
    }

    // Classic presets
    switch (preset) {
      case 1:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
            ),
          ),
          child: Center(
            child: Icon(Icons.school_rounded, color: Colors.white, size: size * 0.45),
          ),
        );
      case 2:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFB300), Color(0xFFE65100)],
            ),
          ),
          child: Center(
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: size * 0.45),
          ),
        );
      case 3:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE64A19), Color(0xFFBF360C)],
            ),
          ),
          child: Center(
            child: Icon(Icons.directions_run_rounded, color: Colors.white, size: size * 0.45),
          ),
        );
      case 4:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00897B), Color(0xFF004D40)],
            ),
          ),
          child: Center(
            child: Icon(Icons.self_improvement_rounded, color: Colors.white, size: size * 0.45),
          ),
        );
      case 0:
      default:
        // Default scenic silhouette
        return Container(
          color: const Color(0xFF38291F),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.4, 0.4),
                    colors: [
                      Color(0xFFFFD199),
                      Color(0xFFE58C5A),
                      Color(0xFF422718),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                child: Column(
                  children: [
                    Container(
                      width: size * 0.18,
                      height: size * 0.18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E130B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: size * 0.32,
                      height: size * 0.32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E130B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: size * 0.65,
                      height: size * 0.3,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E130B),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildIllustratedCartoon(CartoonAvatarItem cartoon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cartoon.gradientStart, cartoon.gradientEnd],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle glow circle in background
          Positioned(
            top: -size * 0.15,
            right: -size * 0.15,
            child: Container(
              width: size * 0.7,
              height: size * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          Icon(
            cartoon.fallbackIcon ?? Icons.face_rounded,
            color: Colors.white,
            size: size * 0.5,
          ),
          Positioned(
            bottom: size * 0.08,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: size * 0.08, vertical: size * 0.02),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
              child: Text(
                cartoon.name,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: size * 0.12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
