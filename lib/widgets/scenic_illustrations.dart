import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// The curved orange brush stroke underneath "Goals" and "Calendar"
class BrushStrokeUnderline extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const BrushStrokeUnderline({
    super.key,
    this.width = 110,
    this.height = 7,
    this.color = AppTheme.primaryOrange,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _BrushStrokePainter(color: color),
      ),
    );
  }
}

class _BrushStrokePainter extends CustomPainter {
  final Color color;

  _BrushStrokePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // A natural curved brush stroke that starts moderate, thickens slightly, and tapers smoothly
    path.moveTo(2, size.height * 0.4);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.85,
      size.width - 2,
      size.height * 0.25,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.98,
      2,
      size.height * 0.8,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BrushStrokePainter oldDelegate) =>
      color != oldDelegate.color;
}

/// Delicate botanical leaf sprig for corners and cards
class BotanicalLeafSprig extends StatelessWidget {
  final double size;
  final Color? color;
  final double angle;

  const BotanicalLeafSprig({
    super.key,
    this.size = 60,
    this.color,
    this.angle = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _BotanicalLeafPainter(
            color: color ?? const Color(0xFFD3BAA0).withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

class _BotanicalLeafPainter extends CustomPainter {
  final Color color;

  _BotanicalLeafPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = color.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final stemPath = Path();
    stemPath.moveTo(size.width * 0.1, size.height * 0.9);
    stemPath.cubicTo(
      size.width * 0.35,
      size.height * 0.65,
      size.width * 0.55,
      size.height * 0.4,
      size.width * 0.85,
      size.height * 0.1,
    );
    canvas.drawPath(stemPath, stemPaint);

    void drawLeaf(double cx, double cy, double rx, double ry, double rot) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rot);
      final oval = Rect.fromCenter(
        center: Offset.zero,
        width: rx * 2,
        height: ry * 2,
      );
      canvas.drawOval(oval, leafPaint);
      canvas.restore();
    }

    // Leaves along the stem
    drawLeaf(size.width * 0.32, size.height * 0.62, 5.5, 3.0, -0.6);
    drawLeaf(size.width * 0.45, size.height * 0.52, 6.5, 3.2, 0.7);
    drawLeaf(size.width * 0.58, size.height * 0.38, 7.0, 3.5, -0.5);
    drawLeaf(size.width * 0.70, size.height * 0.26, 6.5, 3.2, 0.8);
    drawLeaf(size.width * 0.85, size.height * 0.10, 5.0, 2.5, 0.2); // tip
  }

  @override
  bool shouldRepaint(covariant _BotanicalLeafPainter oldDelegate) =>
      color != oldDelegate.color;
}

/// Scenic sunrise landscape with mountain ridges, glowing sun, and backpacker sitting on rock
class ScenicSunriseHeader extends StatelessWidget {
  final double height;
  final double width;
  final bool showPerson;

  const ScenicSunriseHeader({
    super.key,
    this.height = 140,
    this.width = double.infinity,
    this.showPerson = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: CustomPaint(
          size: Size(width, height),
          painter: _ScenicSunrisePainter(showPerson: showPerson),
        ),
      ),
    );
  }
}

class _ScenicSunrisePainter extends CustomPainter {
  final bool showPerson;

  _ScenicSunrisePainter({this.showPerson = true});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Sky Gradient - Soft morning blush to golden amber
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF7ED),
          Color(0xFFFFE8D4),
          Color(0xFFFFD4B2),
          Color(0xFFF9A875),
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // 2. Rising Sun with lens glow
    final sunCenter = Offset(size.width * 0.48, size.height * 0.48);
    final sunGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFFFF0D0).withValues(alpha: 0.9),
          const Color(0xFFFFCC88).withValues(alpha: 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 46));
    canvas.drawCircle(sunCenter, 46, sunGlowPaint);

    // Core bright sun disk
    final coreSun = Paint()..color = const Color(0xFFFFF8EC);
    canvas.drawCircle(sunCenter, 14, coreSun);

    // Subtle sun rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFFAA55).withValues(alpha: 0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - 0.2;
      final start = sunCenter + Offset(math.cos(angle) * 18, math.sin(angle) * 18);
      final end = sunCenter + Offset(math.cos(angle) * 36, math.sin(angle) * 36);
      canvas.drawLine(start, end, rayPaint);
    }

    // 3. Distant soft misty mountain range (Layer 1)
    final distantMountain = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFDF9B78).withValues(alpha: 0.55),
          const Color(0xFFDF9B78).withValues(alpha: 0.85),
        ],
      ).createShader(rect);

    final path1 = Path();
    path1.moveTo(0, size.height * 0.58);
    path1.lineTo(size.width * 0.22, size.height * 0.44);
    path1.lineTo(size.width * 0.42, size.height * 0.52);
    path1.lineTo(size.width * 0.65, size.height * 0.38);
    path1.lineTo(size.width * 0.88, size.height * 0.48);
    path1.lineTo(size.width, size.height * 0.42);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, distantMountain);

    // 4. Midground mountain range (Layer 2)
    final midMountain = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF9E654C),
          const Color(0xFF6B3E2D),
        ],
      ).createShader(rect);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.72);
    path2.lineTo(size.width * 0.28, size.height * 0.60);
    path2.lineTo(size.width * 0.52, size.height * 0.68);
    path2.lineTo(size.width * 0.74, size.height * 0.54);
    path2.lineTo(size.width, size.height * 0.62);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, midMountain);

    // 5. Foreground cliff/rock on right side
    final rockPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF3F271D),
          Color(0xFF26160F),
        ],
      ).createShader(rect);

    final rockPath = Path();
    rockPath.moveTo(size.width * 0.45, size.height);
    rockPath.lineTo(size.width * 0.52, size.height * 0.82);
    rockPath.lineTo(size.width * 0.64, size.height * 0.76);
    rockPath.lineTo(size.width * 0.78, size.height * 0.78);
    rockPath.lineTo(size.width, size.height * 0.82);
    rockPath.lineTo(size.width, size.height);
    rockPath.close();
    canvas.drawPath(rockPath, rockPaint);

    // Small alpine shrubs / texture on rock
    final shrubPaint = Paint()..color = const Color(0xFF1E110A);
    for (int i = 0; i < 5; i++) {
      final sx = size.width * (0.68 + i * 0.06);
      final sy = size.height * 0.78 + (i % 2 == 0 ? 2 : -2);
      canvas.drawCircle(Offset(sx, sy), 3, shrubPaint);
    }

    // 6. Silhouette of Person sitting on rock with backpack looking at sunrise
    if (showPerson) {
      final personPaint = Paint()
        ..color = const Color(0xFF231711)
        ..style = PaintingStyle.fill;

      final px = size.width * 0.67;
      final py = size.height * 0.52;

      // Head with hair bun
      canvas.drawCircle(Offset(px, py), 6.5, personPaint);
      canvas.drawCircle(Offset(px + 1.5, py - 4.5), 3.2, personPaint); // hair bun

      // Torso / Jacket
      final bodyPath = Path();
      bodyPath.moveTo(px - 5, py + 7);
      bodyPath.lineTo(px + 6, py + 7);
      bodyPath.lineTo(px + 7, py + 22);
      bodyPath.lineTo(px - 6, py + 22);
      bodyPath.close();
      canvas.drawPath(bodyPath, personPaint);

      // Backpack on back
      final bagRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(px - 10, py + 8, 7, 13),
        const Radius.circular(3),
      );
      canvas.drawRRect(bagRect, personPaint);

      // Sitting legs drawn up on rock
      final legPath = Path();
      legPath.moveTo(px - 6, py + 20);
      legPath.lineTo(px - 13, py + 26);
      legPath.lineTo(px - 3, py + 29);
      legPath.lineTo(px + 6, py + 23);
      legPath.close();
      canvas.drawPath(legPath, personPaint);

      // Shoes
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px - 14, py + 26), width: 5, height: 3),
        personPaint,
      );

      // Cute little radiating breeze / aura dashes near head
      final auraPaint = Paint()
        ..color = const Color(0xFFC97549).withValues(alpha: 0.7)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(px + 10, py - 6),
        Offset(px + 15, py - 9),
        auraPaint,
      );
      canvas.drawLine(
        Offset(px + 12, py - 2),
        Offset(px + 18, py - 2),
        auraPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScenicSunrisePainter oldDelegate) =>
      showPerson != oldDelegate.showPerson;
}

/// Panoramic motivational banner card with hiker standing on peak
class ScenicHikerBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const ScenicHikerBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow(),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/images/home_banner.jpg',
            width: double.infinity,
            height: 140,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

/// Profile header scenic background with mountain silhouette, glowing sun, and birds
class ScenicProfileHeader extends StatelessWidget {
  final double height;

  const ScenicProfileHeader({super.key, this.height = 180});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ProfileScenicPainter(),
      ),
    );
  }
}

class _ProfileScenicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Soft morning peach wash
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF6EE),
          Color(0xFFFFEBD9),
          Color(0xFFFDE1C8),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Gentle sun glow in upper right
    final sunCenter = Offset(size.width * 0.65, size.height * 0.42);
    final sunGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          const Color(0xFFFFE0B8).withValues(alpha: 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 45));
    canvas.drawCircle(sunCenter, 45, sunGlow);

    // Misty soft mountains in distance
    final mtnPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFDEAA8B).withValues(alpha: 0.4),
          const Color(0xFFC98462).withValues(alpha: 0.65),
        ],
      ).createShader(rect);

    final mtnPath = Path();
    mtnPath.moveTo(size.width * 0.45, size.height);
    mtnPath.lineTo(size.width * 0.60, size.height * 0.58);
    mtnPath.lineTo(size.width * 0.78, size.height * 0.48);
    mtnPath.lineTo(size.width * 0.92, size.height * 0.54);
    mtnPath.lineTo(size.width, size.height * 0.50);
    mtnPath.lineTo(size.width, size.height);
    mtnPath.close();
    canvas.drawPath(mtnPath, mtnPaint);

    // Subtle pine tree forest silhouettes at the mountain base
    final pinePaint = Paint()..color = const Color(0xFF9E6548).withValues(alpha: 0.5);
    for (int i = 0; i < 9; i++) {
      final px = size.width * (0.62 + i * 0.04);
      final py = size.height * 0.68 + (i % 3) * 2;
      final treePath = Path();
      treePath.moveTo(px, py - 9);
      treePath.lineTo(px + 4, py);
      treePath.lineTo(px - 4, py);
      treePath.close();
      canvas.drawPath(treePath, pinePaint);
    }

    // Flying birds in the sky
    final birdPaint = Paint()
      ..color = const Color(0xFFB07658).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    void drawBird(double bx, double by, double wingSpan) {
      final birdPath = Path();
      birdPath.moveTo(bx - wingSpan, by + 2);
      birdPath.quadraticBezierTo(bx - wingSpan * 0.5, by - 2, bx, by);
      birdPath.quadraticBezierTo(bx + wingSpan * 0.5, by - 2, bx + wingSpan, by + 2);
      canvas.drawPath(birdPath, birdPaint);
    }

    drawBird(size.width * 0.54, size.height * 0.28, 4.5);
    drawBird(size.width * 0.59, size.height * 0.23, 5.5);
    drawBird(size.width * 0.63, size.height * 0.31, 3.8);
  }

  @override
  bool shouldRepaint(covariant _ProfileScenicPainter oldDelegate) => false;
}

/// Circular Progress Gauge (68% Completed) with gradient orange stroke
class GoalProgressRing extends StatelessWidget {
  final double percentage; // e.g. 0.68
  final double size;
  final bool isDark;

  const GoalProgressRing({
    super.key,
    required this.percentage,
    this.size = 68,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProgressRingPainter(
          percentage: percentage,
          isDark: isDark,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percentage * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.text(isDark),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Completed',
                style: GoogleFonts.inter(
                  fontSize: 8.5,
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
}

class _ProgressRingPainter extends CustomPainter {
  final double percentage;
  final bool isDark;

  _ProgressRingPainter({required this.percentage, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 9) / 2;
    const strokeWidth = 5.5;

    // Track circle
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF38312B) : const Color(0xFFF2E7DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final sweepAngle = 2 * math.pi * percentage;
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          Color(0xFFFF8B42),
          AppTheme.primaryOrange,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      percentage != oldDelegate.percentage;
}

/// Hand-drawn swirl arrow pointing to "Add your class"
class HandDrawnSwirlArrow extends StatelessWidget {
  final double size;

  const HandDrawnSwirlArrow({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SwirlArrowPainter(),
      ),
    );
  }
}

class _SwirlArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7A685B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Swirling doodle arc
    path.moveTo(size.width * 0.75, size.height * 0.15);
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.75,
      size.width * 0.4,
      size.height * 0.85,
    );
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.85,
      size.width * 0.15,
      size.height * 0.65,
    );
    canvas.drawPath(path, paint);

    // Arrowhead
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.65),
      Offset(size.width * 0.10, size.height * 0.75),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.65),
      Offset(size.width * 0.25, size.height * 0.72),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SwirlArrowPainter oldDelegate) => false;
}
