import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // Master entry controller for choreographed sequence transitions
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _particleCtrl;

  // Staggered Transitions
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;

  late final Animation<double> _greetFade;
  late final Animation<Offset> _greetSlide;

  late final Animation<double> _nameFade;
  late final Animation<Offset> _nameSlide;

  late final Animation<double> _lineWidth;

  late final Animation<double> _subFade;
  late final Animation<Offset> _subSlide;

  late final Animation<double> _btnFade;
  late final Animation<Offset> _btnSlide;

  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Continuous ambient loops
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    // Orchestrated Entrance Transitions (1100ms total)
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // 1. Sunburst Logo (0% -> 40%)
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );
    _logoSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
      ),
    );

    // 2. "Welcome Back" (20% -> 60%)
    _greetFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.18, 0.55, curve: Curves.easeIn),
      ),
    );
    _greetSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.18, 0.58, curve: Curves.easeOutCubic),
      ),
    );

    // 3. "Tarun" Title (32% -> 75%)
    _nameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.30, 0.70, curve: Curves.easeIn),
      ),
    );
    _nameSlide =
        Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.30, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Divider Line (50% -> 80%)
    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.48, 0.78, curve: Curves.easeOut),
      ),
    );

    // 5. "YOUR SCHEDULE IS READY" (58% -> 88%)
    _subFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
      ),
    );
    _subSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.55, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    // 6. "Let's Play" Action Button (68% -> 100%)
    _btnFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.66, 1.0, curve: Curves.easeIn),
      ),
    );
    _btnSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.66, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Ambient Pulse
    _pulse = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Run transition smoothly on load
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (context, anim, secAnim) => const HomeScreen(),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1 : Rising Atmospheric Particles ───────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (context, _) => CustomPaint(
              painter: _ParticlePainter(_particleCtrl.value),
            ),
          ),

          // ── Layer 2 : Pulsing Ambient Glow Ring ──────────────────
          Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Transform.scale(
                scale: _pulse.value,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.04),
                        const Color(0xFFFF6B00).withValues(alpha: 0.025),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 3 : Main Welcome Content ───────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ─ TARC Logo (Official brand emblem with entry transition) ─
                      SlideTransition(
                        position: _logoSlide,
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 22),
                              child: const _TarcLogo(height: 190),
                            ),
                          ),
                        ),
                      ),

                      // ─ "Welcome Back" with smooth transition ──────
                      ClipRect(
                        child: SlideTransition(
                          position: _greetSlide,
                          child: FadeTransition(
                            opacity: _greetFade,
                            child: const Text(
                              'Welcome Back',
                              style: TextStyle(
                                color: Color(0xFFADB5BD),
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 4.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ─ "Tarun" with ShaderMask & transition ───────
                      ClipRect(
                        child: SlideTransition(
                          position: _nameSlide,
                          child: FadeTransition(
                            opacity: _nameFade,
                            child: ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                colors: [
                                  Color(0xFFFFFFFF),
                                  Color(0xFFCFD8DC),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              blendMode: BlendMode.srcIn,
                              child: const Text(
                                'Tarun',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.5,
                                  height: 1.05,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ─ Animated Divider Line ───────────────────────
                      AnimatedBuilder(
                        animation: _lineWidth,
                        builder: (context, _) => Container(
                          width: 56 * _lineWidth.value,
                          height: 1.5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ─ "YOUR SCHEDULE IS READY" with transition ───
                      ClipRect(
                        child: SlideTransition(
                          position: _subSlide,
                          child: FadeTransition(
                            opacity: _subFade,
                            child: const Text(
                              'YOUR SCHEDULE IS READY',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2.8,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 38),

                      // ─ "Let's Play" Action Button (Transitions + Tactile Touch) ─
                      SlideTransition(
                        position: _btnSlide,
                        child: FadeTransition(
                          opacity: _btnFade,
                          child: _LetsPlayButton(
                            onTap: _navigateToHome,
                          ),
                        ),
                      ),
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
}

// ── TARC Official Brand Logo ──────────────────────────────────────────
class _TarcLogo extends StatelessWidget {
  final double height;
  const _TarcLogo({this.height = 190});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.12),
            blurRadius: 32,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/images/tarc_logo.png',
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ── Let's Play Button (Responsive & Tactile) ─────────────────────
class _LetsPlayButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LetsPlayButton({required this.onTap});

  @override
  State<_LetsPlayButton> createState() => _LetsPlayButtonState();
}

class _LetsPlayButtonState extends State<_LetsPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) => _pressCtrl.reverse(),
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 220,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5E00), Color(0xFFFF8C38)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.55),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              splashColor: Colors.white.withValues(alpha: 0.25),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              onTap: _handleTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Let's Play",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Particle Painter ─────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double t;
  static final _particles = List.generate(50, (i) => _P(i));

  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final dot in _particles) {
      final progress = (t + dot.phase) % 1.0;
      final x = dot.nx * size.width;
      final y = size.height * (1.0 - progress) - 20;
      final alpha =
          (math.sin(progress * math.pi)).clamp(0.0, 1.0) * dot.maxAlpha;
      p.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), dot.r, p);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

class _P {
  final double nx;
  final double r;
  final double phase;
  final double maxAlpha;

  _P(int seed)
      : nx = _rng(seed, 0),
        r = 0.8 + _rng(seed, 1) * 2.2,
        phase = _rng(seed, 2),
        maxAlpha = 0.08 + _rng(seed, 3) * 0.18;

  static double _rng(int seed, int salt) =>
      math.Random(seed * 37 + salt * 113).nextDouble();
}
