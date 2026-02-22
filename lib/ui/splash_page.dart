import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

import '../app_flavour.dart';
import '../utils/constants/app_page_id_constants.dart';
import '../utils/constants/translations/common_translation_constants.dart';
import 'splash_controller.dart';
import 'theme/app_color.dart';
import 'theme/app_theme.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<SplashController>(
      init: SplashController(),
      id: AppPageIdConstants.splash,
      builder: (splashController) => Scaffold(
        backgroundColor: AppFlavour.getBackgroundColor(),
        body: _AnimatedSplashBody(splashController: splashController),
      ),
    );
  }
}

class _AnimatedSplashBody extends StatefulWidget {
  final SplashController splashController;

  const _AnimatedSplashBody({required this.splashController});

  @override
  State<_AnimatedSplashBody> createState() => _AnimatedSplashBodyState();
}

class _AnimatedSplashBodyState extends State<_AnimatedSplashBody>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _fadeController;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;

  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Glow pulsation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Particle orbit
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Fade in for text
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    // Generate particles
    for (int i = 0; i < 18; i++) {
      _particles.add(_Particle(
        angle: _random.nextDouble() * 2 * pi,
        radius: 80 + _random.nextDouble() * 80,
        speed: 0.3 + _random.nextDouble() * 0.7,
        size: 2 + _random.nextDouble() * 4,
        opacity: 0.3 + _random.nextDouble() * 0.7,
        drift: _random.nextDouble() * 20 - 10,
      ));
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _particleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = AppColor.getMain();

    return Container(
      decoration: AppTheme.appBoxDecoration,
      child: Stack(
        children: [
          // Orbiting particles
          Center(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(300, 300),
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleController.value,
                    color: mainColor,
                  ),
                );
              },
            ),
          ),

          // Logo + text centered
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing logo
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: mainColor.withAlpha(
                              (120 * _glowAnimation.value).toInt(),
                            ),
                            blurRadius: 40 * _glowAnimation.value,
                            spreadRadius: 10 * _glowAnimation.value,
                          ),
                          BoxShadow(
                            color: Colors.white.withAlpha(
                              (40 * _glowAnimation.value).toInt(),
                            ),
                            blurRadius: 20 * _glowAnimation.value,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: AppFlavour.getSplashImage(),
                ),

                const SizedBox(height: 24),

                // Subtitle with fade-in
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    CommonTranslationConstants.splashSubtitle.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Custom loading indicator
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withAlpha(180),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Dynamic subtitle from controller
                Obx(() => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    widget.splashController.subtitle.value.tr,
                    key: ValueKey(widget.splashController.subtitle.value),
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Particle data model
class _Particle {
  final double angle;
  final double radius;
  final double speed;
  final double size;
  final double opacity;
  final double drift;

  _Particle({
    required this.angle,
    required this.radius,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.drift,
  });
}

// Custom painter for orbiting light particles
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final currentAngle = particle.angle + (progress * 2 * pi * particle.speed);
      final x = center.dx + cos(currentAngle) * particle.radius + sin(progress * pi * 3) * particle.drift;
      final y = center.dy + sin(currentAngle) * particle.radius + cos(progress * pi * 2) * particle.drift;

      // Glow effect per particle
      final glowPaint = Paint()
        ..color = color.withAlpha((particle.opacity * 80).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(x, y), particle.size * 2, glowPaint);

      // Core particle
      final corePaint = Paint()
        ..color = Colors.white.withAlpha((particle.opacity * 220).toInt());
      canvas.drawCircle(Offset(x, y), particle.size, corePaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => oldDelegate.progress != progress;
}
