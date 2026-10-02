import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/core/constants/app_constants.dart';
import 'package:aig/core/providers/core_providers.dart';
import 'package:aig/core/config/app_config.dart';
import 'package:aig/features/auth/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

class AuthSplashScreen extends ConsumerStatefulWidget {
  const AuthSplashScreen({super.key});

  @override
  ConsumerState<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends ConsumerState<AuthSplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _contentFade = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOut,
  );

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[AIG_STARTUP] Splash mounted');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      _completeStartup();
    });
  }

  Timer? _startupWatchdog;

  Future<void> _completeStartup() async {
    if (_hasNavigated) {
      return;
    }

    debugPrint('[AIG_STARTUP] Essential initialization started');

    // Start a cancellable watchdog timer to guarantee progress even if
    // initialization hangs. The watchdog is cancelled when initialization
    // completes.
    _startupWatchdog = Timer(const Duration(seconds: 3), () {
      debugPrint('[AIG_STARTUP_ERROR] Essential initialization timed out');
      _proceedAfterInit();
    });

    // Hardware testing does not require Firebase authentication.
    if (AppConfig.enableLocalTestingMode) {
      _proceedAfterInit();
      return;
    }

    try {
      try {
        await ref.read(firebaseInitializerProvider).initialize();
      } catch (error, stack) {
        debugPrint('[AIG_STARTUP_ERROR] firebase initialize failed');
        debugPrint('$error');
        debugPrint('$stack');
      }

      try {
        await ref.read(authStateNotifierProvider).restoreSession();
      } catch (error, stack) {
        debugPrint('[AIG_STARTUP_ERROR] auth restore failed');
        debugPrint('$error');
        debugPrint('$stack');
      }
    } finally {
      if (!_hasNavigated) {
        _proceedAfterInit();
      }
    }
  }

  void _proceedAfterInit() {
    if (_hasNavigated) return;
    _startupWatchdog?.cancel();
    _startupWatchdog = null;
    _hasNavigated = true;

    debugPrint('[AIG_STARTUP] Essential initialization completed');
    if (AppConfig.enableLocalTestingMode) {
      debugPrint('[AIG_STARTUP] Navigating to dashboard in hardware test mode');
      context.replace(AppRoutePath.dashboard);
      return;
    }

    final state = ref.read(authStateNotifierProvider).state;
    final target = state.isAuthenticated ? AppRoutePath.dashboard : AppRoutePath.login;
    debugPrint('[AIG_STARTUP] Navigating to $target (isAuthenticated=${state.isAuthenticated}, isSessionRestored=${state.isSessionRestored})');
    if (state.isSessionRestored) {
      context.replace(target);
    } else {
      context.replace(AppRoutePath.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _startupWatchdog?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SplashColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _SplashBackground()),
          FadeTransition(
            opacity: _contentFade,
            child: const _SplashContent(),
          ),
        ],
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _WorldMapPatternPainter(),
          ),
        ),
        Positioned(
          left: -60,
          top: -60,
          width: 260,
          height: 260,
          child: Transform.rotate(
            angle: -0.5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_SplashColors.ribbonGold, _SplashColors.ribbonGoldAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(160),
                  topLeft: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _SplashColors.ribbonGold.withAlpha((0.24 * 255).round()),
                    blurRadius: 32,
                    offset: const Offset(12, 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: -40,
          bottom: -40,
          width: 340,
          height: 320,
          child: Transform.rotate(
            angle: 0.38,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _SplashColors.ribbonGoldAccent.withAlpha((0.88 * 255).round()),
                    _SplashColors.ribbonGold.withAlpha((0.26 * 255).round()),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(180),
                  bottomRight: Radius.circular(80),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _SplashColors.ribbonGold.withAlpha((0.18 * 255).round()),
                    blurRadius: 28,
                    offset: const Offset(-18, -8),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          right: 24,
          bottom: 40,
          child: _DiamondAccent(size: 68, opacity: 0.24),
        ),
        const Positioned(
          left: 24,
          bottom: 120,
          child: _DiamondAccent(size: 54, opacity: 0.18),
        ),
        const Positioned(
          left: 16,
          top: 110,
          child: _DiamondAccent(size: 38, opacity: 0.18),
        ),
      ],
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            const _BrandBadge(),
            const SizedBox(height: 28),
            const _BrandText(),
            const SizedBox(height: 18),
            const _TaglineRow(),
            const SizedBox(height: 42),
            const _LoadingSection(),
          ],
        ),
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(42),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).round()),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: _BadgeWorldMap()),
          const Positioned.fill(child: _BadgeRing()),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DiamondIcon(size: 44),
              const SizedBox(height: 14),
              Text(
                'AIG',
                style: TextStyle(
                  fontSize: 68,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [_SplashColors.goldText, _SplashColors.goldHighlight],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(const Rect.fromLTWH(0, 0, 260, 120)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Accredited Institute of Gemology',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _SplashColors.primaryText,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeWorldMap extends StatelessWidget {
  const _BadgeWorldMap();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: CustomPaint(
        painter: _WorldMapPatternPainter(color: _SplashColors.mapTeal.withAlpha((0.16 * 255).round()), dotSize: 4),
      ),
    );
  }
}

class _BadgeRing extends StatelessWidget {
  const _BadgeRing();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(280, 280),
      painter: _BadgeRingPainter(),
    );
  }
}

class _BrandText extends StatelessWidget {
  const _BrandText();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text(
          'ACCREDITED INSTITUTE',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _SplashColors.goldText,
            letterSpacing: 2.3,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'OF GEMOLOGY',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _SplashColors.goldText,
            letterSpacing: 2.3,
          ),
        ),
      ],
    );
  }
}

class _TaglineRow extends StatelessWidget {
  const _TaglineRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _TaglineText('EXCELLENCE'),
        SizedBox(width: 10),
        _TaglineDot(),
        SizedBox(width: 10),
        _TaglineText('INTEGRITY'),
        SizedBox(width: 10),
        _TaglineDot(),
        SizedBox(width: 10),
        _TaglineText('KNOWLEDGE'),
      ],
    );
  }
}

class _TaglineText extends StatelessWidget {
  const _TaglineText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _SplashColors.primaryText,
        letterSpacing: 1.9,
      ),
    );
  }
}

class _TaglineDot extends StatelessWidget {
  const _TaglineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: _SplashColors.accentTeal,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SizedBox(height: 12),
        SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: _SplashColors.goldText,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Loading...',
          style: TextStyle(
            color: _SplashColors.secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SplashColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF2E2E2E);
  static const Color secondaryText = Color(0xFF6F6F6F);
  static const Color goldText = Color(0xFFB6902F);
  static const Color goldHighlight = Color(0xFFF0D281);
  static const Color ribbonGold = Color(0xFFD8BA79);
  static const Color ribbonGoldAccent = Color(0xFFF7E8C9);
  static const Color mapTeal = Color(0xFF66B7B5);
  static const Color accentTeal = Color(0xFF42C4D5);
}

class _WorldMapPatternPainter extends CustomPainter {
  _WorldMapPatternPainter({this.color = const Color(0xFF66B7B5), this.dotSize = 5});

  final Color color;
  final double dotSize;

  static const List<List<Offset>> _continentDots = [
    [
      Offset(0.08, 0.46),
      Offset(0.12, 0.42),
      Offset(0.16, 0.44),
      Offset(0.20, 0.40),
      Offset(0.24, 0.44),
      Offset(0.28, 0.46),
    ],
    [
      Offset(0.34, 0.30),
      Offset(0.40, 0.32),
      Offset(0.44, 0.28),
      Offset(0.48, 0.30),
      Offset(0.52, 0.26),
      Offset(0.56, 0.28),
    ],
    [
      Offset(0.62, 0.38),
      Offset(0.68, 0.34),
      Offset(0.74, 0.36),
      Offset(0.80, 0.32),
      Offset(0.84, 0.38),
    ],
    [
      Offset(0.20, 0.64),
      Offset(0.24, 0.66),
      Offset(0.28, 0.70),
      Offset(0.32, 0.72),
      Offset(0.36, 0.68),
    ],
    [
      Offset(0.52, 0.66),
      Offset(0.56, 0.70),
      Offset(0.60, 0.68),
      Offset(0.64, 0.72),
      Offset(0.68, 0.68),
    ],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final cluster in _continentDots) {
      for (final point in cluster) {
        canvas.drawCircle(Offset(point.dx * size.width, point.dy * size.height), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BadgeRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringPaint = Paint()
      ..color = _SplashColors.goldText.withAlpha((0.24 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;

    canvas.drawCircle(center, size.width * 0.35, ringPaint);

    final diamondPaint = Paint()..color = _SplashColors.goldText;
    final radius = size.width * 0.39;
    const shapeSize = 10.0;
    for (var i = 0; i < 16; i++) {
      final angle = (math.pi * 2 / 16) * i;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      final path = Path()
        ..moveTo(x, y - shapeSize)
        ..lineTo(x + shapeSize, y)
        ..lineTo(x, y + shapeSize)
        ..lineTo(x - shapeSize, y)
        ..close();
      canvas.drawPath(path, diamondPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiamondIcon extends StatelessWidget {
  const _DiamondIcon({this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.68),
      painter: _DiamondPainter(),
    );
  }
}

class _DiamondAccent extends StatelessWidget {
  const _DiamondAccent({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(size, size * 0.7),
        painter: _DiamondPainter(color: _SplashColors.goldText),
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  const _DiamondPainter({this.color = _SplashColors.accentTeal});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final width = size.width;
    final height = size.height;
    final path = Path()
      ..moveTo(width * 0.5, 0)
      ..lineTo(width, height * 0.4)
      ..lineTo(width * 0.5, height)
      ..lineTo(0, height * 0.4)
      ..close();
    canvas.drawShadow(path, Colors.black.withAlpha((0.12 * 255).round()), 4, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
