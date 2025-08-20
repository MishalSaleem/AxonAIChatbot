import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

// A centralized place for your app's beautiful color palette.
class AppColors {
  static const Color crystalBlue = Color(0xFFD6EFFF);
  static const Color etherealPink = Color(0xFFFFD6F5);
  static const Color deepSpace = Color(0xFF0A0514);
  static const Color textPrimary = Color(0xFFEAE6F3);
  static const Color textSecondary = Color(0xFFB8B0C8);
  static const Color accentGlow = Color(0xFF9D4EDD);
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _rippleController;
  late AnimationController _shardController;
  Offset _pointerPosition = Offset.zero;
  bool _isMenuVisible = false;
  final List<Offset> _rippleOrigins = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _rippleController.dispose();
    _shardController.dispose();
    super.dispose();
  }

  void _updatePointerPosition(PointerEvent event) {
    setState(() => _pointerPosition = event.localPosition);
  }

  void _toggleMenu() {
    setState(() {
      _isMenuVisible = !_isMenuVisible;
      if (_isMenuVisible) {
        _shardController.forward();
        _addRippleEffect(MediaQuery.of(context).size.center(Offset.zero));
      } else {
        _shardController.reverse();
      }
    });
  }

  void _addRippleEffect(Offset origin) {
    setState(() {
      _rippleOrigins.add(origin);
      _rippleController.reset();
      _rippleController.forward().then((_) {
        setState(() => _rippleOrigins.remove(origin));
      });
    });
  }

  void _handleCharacterTap() {
    _addRippleEffect(_pointerPosition);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepSpace,
      body: Listener(
        onPointerMove: _updatePointerPosition,
        onPointerHover: _updatePointerPosition,
        child: Stack(
          children: [
            // Animated background with parallax
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: InteractiveNebulaPainter(
                      _controller.value, _pointerPosition),
                  size: MediaQuery.of(context).size,
                );
              },
            ),
            // Ripple effects
            ..._rippleOrigins.map((origin) {
              return AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) {
                  return Positioned.fill(
                    child: CustomPaint(
                      painter: CrystalRipplePainter(
                        origin: origin,
                        progress: _rippleController.value,
                      ),
                    ),
                  );
                },
              );
            }),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Text(
                    'Welcome to AXON',
                    style: GoogleFonts.exo2(
                      fontSize: 42,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms) // Optimized
                      .slideY(begin: -0.5),
                  const SizedBox(height: 8),
                  Text(
                    'The Crystal Oracle Awaits Your Query',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms) // Optimized
                      .slideY(begin: -0.5),
                  Expanded(
                    child: _buildInteractiveCharacter(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const ChatScreen(),
                            transitionDuration:
                                const Duration(milliseconds: 700),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                  opacity: animation, child: child);
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary.withOpacity(0.9),
                        foregroundColor: AppColors.deepSpace,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 20),
                        elevation: 15,
                        shadowColor: AppColors.textPrimary.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start New Chat',
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 600.ms) // Optimized
                      .slideY(begin: 0.5),
                ],
              ),
            ),
            // --- The "Crystal Shatter" Menu ---
            _CrystalMenuButton(onTap: _toggleMenu),
            if (_isMenuVisible)
              _CrystalShatterMenu(
                onClose: _toggleMenu,
                shardProgress: _shardController.value,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveCharacter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final tiltX =
            (_pointerPosition.dy / size.height - 0.5).clamp(-1.0, 1.0) * 0.2;
        final tiltY =
            -(_pointerPosition.dx / size.width - 0.5).clamp(-1.0, 1.0) * 0.2;
        final perspective = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(tiltX)
          ..rotateY(tiltY);
        return Animate(
          effects: const [
            FadeEffect(
                duration: Duration(milliseconds: 600), // Optimized
                delay: Duration(milliseconds: 500)) // Optimized
          ],
          child: Transform(
            alignment: Alignment.center,
            transform: perspective,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Crystal glow effect - reduced brightness
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: CrystalGlowPainter(_controller.value),
                      size: size,
                    );
                  },
                ),
                // Interactive character with ripple effect
                GestureDetector(
                  onTap: _handleCharacterTap,
                  child: Hero(
                    tag: 'bot-hero',
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final floatAngle = _controller.value * 2 * math.pi;
                        return Transform.translate(
                          offset: Offset(0, math.sin(floatAngle) * 15),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.etherealPink.withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color:
                                      AppColors.crystalBlue.withOpacity(0.15),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset('assets/images/logo.png',
                                  height: size.height * 0.55),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CrystalMenuButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CrystalMenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      left: 24,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 150,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.crystalBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.crystalBlue.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.tune_rounded,
                      color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Automations',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(delay: 800.ms, duration: 600.ms) // Optimized
          .slideX(begin: -1.0, curve: Curves.easeOutCubic),
    );
  }
}

class _CrystalShatterMenu extends StatefulWidget {
  final VoidCallback onClose;
  final double shardProgress;
  const _CrystalShatterMenu({
    required this.onClose,
    required this.shardProgress,
  });

  @override
  State<_CrystalShatterMenu> createState() => _CrystalShatterMenuState();
}

class _CrystalShatterMenuState extends State<_CrystalShatterMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _menuController;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this)
      ..forward();
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _close() {
    _menuController.reverse().whenComplete(() => widget.onClose());
  }

  void _navigateToFeature(String feature) {
    _close();
    HapticFeedback.mediumImpact();
    switch (feature) {
      case 'new_chat':
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ChatScreen(),
            transitionDuration: const Duration(milliseconds: 700),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
        break;
      case 'settings':
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const SettingsScreen(),
            transitionDuration: const Duration(milliseconds: 700),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
        break;
      case 'about':
        _showAboutDialog();
        break;
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      barrierColor: AppColors.deepSpace.withOpacity(0.8),
      builder: (context) => _CrystalDialog(
        title: 'About AXON',
        content:
            'Crystal Oracle • Quantum Intelligence\n\nVersion 2.1.0\nCreated with ❤ by Crystal Oracle Labs',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(
                  color: AppColors.accentGlow,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: _close,
            child: AnimatedBuilder(
              animation: _menuController,
              builder: (context, child) {
                return CustomPaint(
                  painter: CrystalShatterPainter(
                    animationValue: CurvedAnimation(
                      parent: _menuController,
                      curve: Curves.easeOutCubic,
                    ).value,
                    shardProgress: widget.shardProgress,
                  ),
                  size: MediaQuery.of(context).size,
                );
              },
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMenuItem(
                    Icons.add_comment_outlined, "New Chat", 'new_chat', 0),
                _buildMenuItem(
                    Icons.settings_outlined, "Settings", 'settings', 1),
                _buildMenuItem(
                    Icons.info_outline_rounded, "About AXON", 'about', 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      IconData icon, String title, String feature, int index) {
    final directions = [
      const Offset(-1, -1),
      const Offset(1, -1),
      const Offset(-1, 1),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: GestureDetector(
        onTap: () => _navigateToFeature(feature),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: 240,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.deepSpace.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.crystalBlue.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(left: 14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.crystalBlue.withOpacity(0.3),
                          AppColors.crystalBlue.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.crystalBlue.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: AppColors.textPrimary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.exo2(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(controller: _menuController)
        .fadeIn(delay: (150 + index * 100).ms, duration: 300.ms)
        .move(
          begin: directions[index] * 60,
          end: Offset.zero,
          curve: Curves.easeOutBack,
          delay: (150 + index * 100).ms,
        );
  }
}

class CrystalShatterPainter extends CustomPainter {
  final double animationValue;
  final double shardProgress;
  final Paint shardPaint;
  final List<Path> _shards = [];

  CrystalShatterPainter({
    required this.animationValue,
    required this.shardProgress,
  }) : shardPaint = Paint() {
    if (_shards.isEmpty) {
      final random = math.Random(42);
      // Reduced number of shards for better performance
      for (int i = 0; i < 10; i++) {
        final path = Path();
        // Position shards away from center
        final angle = random.nextDouble() * 2 * math.pi;
        final distance =
            0.35 + random.nextDouble() * 0.35; // 35-70% from center
        final p1 = Offset(
          0.5 + math.cos(angle) * distance,
          0.5 + math.sin(angle) * distance,
        );
        final p2 = Offset(
          p1.dx + (random.nextDouble() - 0.5) * 0.15,
          p1.dy + (random.nextDouble() - 0.5) * 0.15,
        );
        final p3 = Offset(
          p1.dx + (random.nextDouble() - 0.5) * 0.15,
          p1.dy + (random.nextDouble() - 0.5) * 0.15,
        );
        path.moveTo(p1.dx, p1.dy);
        path.lineTo(p2.dx, p2.dy);
        path.lineTo(p3.dx, p3.dy);
        path.close();
        _shards.add(path);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    shardPaint.imageFilter = ui.ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8);

    for (int i = 0; i < _shards.length; i++) {
      final path = _shards[i];
      final matrix = Matrix4.identity();
      final rect = path.getBounds();
      final pathCenter = rect.center;
      final distance = (pathCenter - const Offset(0.5, 0.5)).distance;

      // Animate shards based on both menu and shard animations (original behavior)
      final combinedProgress = (animationValue + shardProgress) / 2;
      final translation =
          Offset.lerp(pathCenter, const Offset(0.5, 0.5), combinedProgress)!;
      final rotation = ui.lerpDouble(
          0.0, (i.isEven ? -1 : 1) * math.pi / 6, combinedProgress)!;

      matrix.translate(
          translation.dx * size.width, translation.dy * size.height);
      matrix.translate(
          -pathCenter.dx * size.width, -pathCenter.dy * size.height);
      matrix.translate(pathCenter.dx * size.width, pathCenter.dy * size.height);
      matrix.rotateZ(rotation);
      matrix.translate(
          -pathCenter.dx * size.width, -pathCenter.dy * size.height);

      final scaledPath = path.transform(
          Matrix4.diagonal3Values(size.width, size.height, 1.0).storage);
      final transformedPath = scaledPath.transform(matrix.storage);

      // Significantly reduced opacity to ensure menu items are readable
      final opacity =
          (1.0 - (distance * 0.7)) * (0.3 - combinedProgress * 0.15);
      shardPaint.color = Color.lerp(AppColors.crystalBlue,
              AppColors.etherealPink, i / _shards.length)!
          .withOpacity(opacity.clamp(0.0, 0.2));

      canvas.drawPath(transformedPath, shardPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class InteractiveNebulaPainter extends CustomPainter {
  final double animationValue;
  final Offset pointerPosition;
  final Paint particlePaint;

  InteractiveNebulaPainter(this.animationValue, this.pointerPosition)
      : particlePaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(123);
    // Create parallax effect based on pointer position
    final parallaxX = (pointerPosition.dx / size.width - 0.5) * 20;
    final parallaxY = (pointerPosition.dy / size.height - 0.5) * 20;

    for (int i = 0; i < 60; i++) {
      // Reduced from 80 to 60 for performance
      final x = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final speed = random.nextDouble() * 20 + 10;
      final y = (startY - animationValue * speed) % size.height;
      // Apply parallax effect
      final parallaxFactor = 0.5 + random.nextDouble() * 0.5;
      final particlePos = Offset(
        x + parallaxX * parallaxFactor,
        y + parallaxY * parallaxFactor,
      );
      final distanceToPointer = (pointerPosition - particlePos).distance;
      final repelFactor = 1 - (distanceToPointer / 200).clamp(0.0, 1.0);
      final angleToPointer = (particlePos - pointerPosition).direction;
      final repelOffset =
          Offset.fromDirection(angleToPointer, repelFactor * 50);
      final finalPos = particlePos + repelOffset;
      final opacity = random.nextDouble() * 0.6; // Reduced from 0.7
      particlePaint.shader =
          ui.Gradient.radial(finalPos, 15.0 + repelFactor * 25, [
        // Reduced size
        Color.lerp(AppColors.etherealPink, AppColors.crystalBlue,
                random.nextDouble())!
            .withOpacity(opacity * repelFactor * 1.5), // Reduced multiplier
        Colors.transparent,
      ]);
      canvas.drawCircle(finalPos, 15.0 + repelFactor * 25, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CrystalGlowPainter extends CustomPainter {
  final double animationValue;
  final Paint glowPaint;

  CrystalGlowPainter(this.animationValue) : glowPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        size.width * 0.2 + math.sin(animationValue * 2 * math.pi) * 15;
    // Multi-layered glow effect with reduced brightness
    for (int i = 0; i < 3; i++) {
      final layerRadius = radius * (1.0 + i * 0.3);
      final layerOpacity = 0.08 - i * 0.03; // Further reduced
      glowPaint.shader = ui.Gradient.radial(
        center,
        layerRadius,
        [
          AppColors.etherealPink.withOpacity(layerOpacity),
          AppColors.crystalBlue.withOpacity(layerOpacity * 0.7),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );
      glowPaint.maskFilter =
          ui.MaskFilter.blur(ui.BlurStyle.normal, 20 + i * 5); // Reduced blur
      canvas.drawCircle(center, layerRadius, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CrystalRipplePainter extends CustomPainter {
  final Offset origin;
  final double progress;

  CrystalRipplePainter({required this.origin, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppColors.crystalBlue.withOpacity(0.7 * (1 - progress));
    // Draw multiple expanding ripples
    for (int i = 0; i < 3; i++) {
      final rippleProgress = (progress + i * 0.2).clamp(0.0, 1.0);
      final radius = rippleProgress * 300;
      final opacity = (1 - rippleProgress) * 0.5;
      paint.color = Color.lerp(
        AppColors.crystalBlue,
        AppColors.etherealPink,
        i / 3,
      )!
          .withOpacity(opacity);
      canvas.drawCircle(origin, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CrystalDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<Widget> actions;

  const _CrystalDialog({
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.deepSpace.withOpacity(0.95),
            border: Border.all(
              color: AppColors.accentGlow.withOpacity(0.6), // Using accentGlow
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.accentGlow.withOpacity(0.3), // Using accentGlow
                blurRadius: 20,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: AppColors.accentGlow, // Heart icon in accentGlow
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.exo2(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                content,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
