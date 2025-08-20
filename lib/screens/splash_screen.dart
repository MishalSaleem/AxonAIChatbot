import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _loopingController;
  bool _isExiting = false;

  static const Color crystalBlue = Color(0xFFD6EFFF);
  static const Color etherealPink = Color(0xFFFFD6F5);
  static const Color deepSpace = Color(0xFF0A0514);
  static const Color textPrimary = Color(0xFFEAE6F3);
  static const Color textSecondary = Color(0xFFB8B0C8);

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..forward();

    _loopingController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    Future.delayed(const Duration(milliseconds: 5000), () {
      if (mounted) {
        setState(() => _isExiting = true);
        Future.delayed(const Duration(milliseconds: 1000), () {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const HomeScreen(),
              transitionDuration: const Duration(milliseconds: 800),
              transitionsBuilder: (context, animation, secondary, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    _loopingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepSpace,
      body: AnimatedOpacity(
        opacity: _isExiting ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _loopingController,
              builder: (context, child) {
                return CustomPaint(
                  painter: StardustPainter(_loopingController.value),
                  size: MediaQuery.of(context).size,
                );
              },
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  SizedBox(
                    width: 400,
                    height: 400,
                    child: AnimatedBuilder(
                      animation: Listenable.merge(
                          [_revealController, _loopingController]),
                      builder: (context, child) {
                        final floatAngle =
                            _loopingController.value * 2 * math.pi;
                        final perspective = Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..translate(0.0, math.sin(floatAngle) * 10)
                          ..rotateY(math.cos(floatAngle) * 0.1);

                        return Transform(
                          transform: perspective,
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                painter: CrystallineAwakeningPainter(
                                    _revealController.value),
                                size: const Size(400, 400),
                              ),
                              Opacity(
                                opacity: (_revealController.value - 0.6)
                                        .clamp(0.0, 1.0) /
                                    0.4,
                                child: Image.asset('assets/images/logo.png'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'AXON',
                    style: GoogleFonts.montserrat(
                      fontSize: 80,
                      fontWeight: FontWeight.w300,
                      color: textPrimary,
                      letterSpacing: 18,
                    ),
                  ).animate(delay: 2000.ms).fadeIn(duration: 1200.ms).shimmer(
                      duration: 1500.ms, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Quantum Intelligence Evolved',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: textSecondary,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2,
                    ),
                  ).animate(delay: 2200.ms).fadeIn(duration: 1200.ms),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CrystallineAwakeningPainter extends CustomPainter {
  final double animationValue;
  final Paint linePaint;
  final Paint glowPaint;

  CrystallineAwakeningPainter(this.animationValue)
      : linePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
        glowPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final Path leftWingPath = _createWingPath(size, isLeft: true);
    final Path rightWingPath = _createWingPath(size, isLeft: false);

    double revealProgress = Curves.easeInOut.transform(animationValue);

    if (revealProgress < 0.7) {
      final double drawLength = revealProgress / 0.7;
      _drawAnimatedPath(canvas, leftWingPath, drawLength);
      _drawAnimatedPath(canvas, rightWingPath, drawLength);
    }

    if (revealProgress > 0.5) {
      final flashProgress = (revealProgress - 0.5) / 0.2;
      final flashRadius = flashProgress * size.width * 0.5;
      final flashOpacity = math.sin(flashProgress * math.pi);

      glowPaint.shader = ui.Gradient.radial(
        center,
        flashRadius,
        [
          Colors.white.withOpacity(flashOpacity * 0.8),
          _SplashScreenState.crystalBlue.withOpacity(flashOpacity * 0.4),
          Colors.transparent
        ],
        [0.0, 0.3, 1.0],
      );
      canvas.drawCircle(center, flashRadius, glowPaint);
    }
  }

  void _drawAnimatedPath(Canvas canvas, Path path, double drawLength) {
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(0.0, metric.length * drawLength);

      final gradientRect =
          Rect.fromPoints(const Offset(-50, -50), const Offset(250, 250));
      linePaint.shader = const LinearGradient(
        colors: [
          _SplashScreenState.crystalBlue,
          _SplashScreenState.etherealPink
        ],
      ).createShader(gradientRect);

      linePaint.strokeWidth = 4.0;
      linePaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(extractPath, linePaint);

      linePaint.strokeWidth = 1.5;
      linePaint.maskFilter = null;
      linePaint.color = Colors.white;
      canvas.drawPath(extractPath, linePaint);
    }
  }

  Path _createWingPath(Size size, {required bool isLeft}) {
    final scale = size.width / 200.0;
    final sign = isLeft ? -1.0 : 1.0;
    final center = Offset(size.width / 2, size.height / 2);

    Path path = Path();
    path.moveTo(center.dx + sign * 15 * scale, center.dy - 20 * scale);
    path.cubicTo(
        center.dx + sign * 80 * scale,
        center.dy - 60 * scale,
        center.dx + sign * 60 * scale,
        center.dy - 120 * scale,
        center.dx + sign * 90 * scale,
        center.dy - 160 * scale);
    path.cubicTo(
        center.dx + sign * 70 * scale,
        center.dy - 110 * scale,
        center.dx + sign * 40 * scale,
        center.dy - 80 * scale,
        center.dx + sign * 20 * scale,
        center.dy - 40 * scale);
    path.moveTo(center.dx + sign * 25 * scale, center.dy - 30 * scale);
    path.quadraticBezierTo(center.dx + sign * 70 * scale, center.dy,
        center.dx + sign * 30 * scale, center.dy + 100 * scale);
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StardustPainter extends CustomPainter {
  final double animationValue;
  final Paint particlePaint;

  StardustPainter(this.animationValue) : particlePaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(123);
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final speed = random.nextDouble() * 20 + 10;
      final y = (startY + animationValue * speed) % size.height;

      final opacity = random.nextDouble() * 0.5;
      particlePaint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.5, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
