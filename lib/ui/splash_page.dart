import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

import '../app_flavour.dart';
import '../utils/constants/app_page_id_constants.dart';
import '../utils/constants/translations/common_translation_constants.dart';
import 'splash_animations.dart';
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

  late SplashAnimationDelegate _animation;

  @override
  void initState() {
    super.initState();

    // Get the flavour-specific animation delegate
    _animation = AppFlavour.getSplashAnimation();
    _animation.initialize(Random());

    // Glow pulsation (shared across all flavours)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Particle/animation cycle (duration from delegate)
    _particleController = AnimationController(
      vsync: this,
      duration: _animation.cycleDuration,
    )..repeat();

    // Fade in for text
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

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
          // Flavour-specific animation
          Center(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(300, 300),
                  painter: _animation.createPainter(
                    progress: _particleController.value,
                    color: mainColor,
                    size: const Size(300, 300),
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
                      AppColor.textSecondary,
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
