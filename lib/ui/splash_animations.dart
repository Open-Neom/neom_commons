import 'dart:math';

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
// SPLASH ANIMATION DELEGATE — Abstract Strategy
// ═══════════════════════════════════════════════════════════════════

/// Defines a splash screen animation style.
///
/// Each app flavour provides its own [SplashAnimationDelegate] via
/// [AppFlavour.getSplashAnimation()]. The delegate creates the
/// [CustomPainter] used by [SplashPage] to render the background effect.
abstract class SplashAnimationDelegate {
  /// Initialize animation data (particles, waves, etc.).
  void initialize(Random random);

  /// Duration of one animation cycle.
  Duration get cycleDuration;

  /// Creates the [CustomPainter] for the current frame.
  CustomPainter createPainter({
    required double progress,
    required Color color,
    required Size size,
  });
}

// ═══════════════════════════════════════════════════════════════════
// 1. SOUND WAVES — Gigmeout (g)
// Concentric rings expanding outward like sound waves + note particles
// ═══════════════════════════════════════════════════════════════════

class _SoundWave {
  final double phase;
  final double maxRadius;
  final double thickness;

  _SoundWave({
    required this.phase,
    required this.maxRadius,
    required this.thickness,
  });
}

class _NoteParticle {
  final double angle;
  final double speed;
  final double size;
  final double startRadius;

  _NoteParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.startRadius,
  });
}

class SoundWaveDelegate extends SplashAnimationDelegate {
  final List<_SoundWave> _waves = [];
  final List<_NoteParticle> _notes = [];

  @override
  Duration get cycleDuration => const Duration(seconds: 3);

  @override
  void initialize(Random random) {
    // 5 staggered rings
    for (int i = 0; i < 5; i++) {
      _waves.add(_SoundWave(
        phase: i * 0.2,
        maxRadius: 160 + random.nextDouble() * 40,
        thickness: 1.5 + random.nextDouble() * 1.5,
      ));
    }
    // 8 floating note particles
    for (int i = 0; i < 8; i++) {
      _notes.add(_NoteParticle(
        angle: random.nextDouble() * 2 * pi,
        speed: 0.4 + random.nextDouble() * 0.6,
        size: 2 + random.nextDouble() * 2.5,
        startRadius: 40 + random.nextDouble() * 60,
      ));
    }
  }

  @override
  CustomPainter createPainter({
    required double progress,
    required Color color,
    required Size size,
  }) {
    return _SoundWavePainter(
      waves: _waves,
      notes: _notes,
      progress: progress,
      color: color,
    );
  }
}

class _SoundWavePainter extends CustomPainter {
  final List<_SoundWave> waves;
  final List<_NoteParticle> notes;
  final double progress;
  final Color color;

  _SoundWavePainter({
    required this.waves,
    required this.notes,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw expanding rings
    for (final wave in waves) {
      final waveProgress = (progress + wave.phase) % 1.0;
      final radius = waveProgress * wave.maxRadius;
      final alpha = (1.0 - waveProgress) * 0.6;

      if (alpha > 0.02) {
        // Glow ring
        final glowPaint = Paint()
          ..color = color.withAlpha((alpha * 60).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = wave.thickness * 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(center, radius, glowPaint);

        // Core ring
        final ringPaint = Paint()
          ..color = Colors.white.withAlpha((alpha * 180).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = wave.thickness;
        canvas.drawCircle(center, radius, ringPaint);
      }
    }

    // Draw note particles drifting outward
    for (final note in notes) {
      final notePhase = (progress * note.speed * 2) % 1.0;
      final noteRadius = note.startRadius + notePhase * 100;
      final noteAngle = note.angle + progress * pi * note.speed;
      final noteAlpha = (1.0 - notePhase) * 0.7;

      if (noteAlpha > 0.05) {
        final x = center.dx + cos(noteAngle) * noteRadius;
        final y = center.dy + sin(noteAngle) * noteRadius - notePhase * 30;

        final glowPaint = Paint()
          ..color = color.withAlpha((noteAlpha * 80).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset(x, y), note.size * 2, glowPaint);

        final corePaint = Paint()
          ..color = Colors.white.withAlpha((noteAlpha * 200).toInt());
        canvas.drawCircle(Offset(x, y), note.size, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_SoundWavePainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
// 2. RISING PAGES — Emxi (e)
// Rectangular "page" particles drifting upward with rotation & sway
// ═══════════════════════════════════════════════════════════════════

class _PageParticle {
  final double xOffset;
  final double startY;
  final double width;
  final double height;
  final double speed;
  final double opacity;
  final double swayFreq;
  final double swayAmp;
  final double rotSpeed;

  _PageParticle({
    required this.xOffset,
    required this.startY,
    required this.width,
    required this.height,
    required this.speed,
    required this.opacity,
    required this.swayFreq,
    required this.swayAmp,
    required this.rotSpeed,
  });
}

class RisingPagesDelegate extends SplashAnimationDelegate {
  final List<_PageParticle> _pages = [];

  @override
  Duration get cycleDuration => const Duration(seconds: 4);

  @override
  void initialize(Random random) {
    for (int i = 0; i < 14; i++) {
      _pages.add(_PageParticle(
        xOffset: (random.nextDouble() - 0.5) * 200,
        startY: random.nextDouble(),
        width: 3 + random.nextDouble() * 5,
        height: 4 + random.nextDouble() * 6,
        speed: 0.5 + random.nextDouble() * 0.5,
        opacity: 0.3 + random.nextDouble() * 0.5,
        swayFreq: 0.5 + random.nextDouble() * 1.5,
        swayAmp: 15 + random.nextDouble() * 20,
        rotSpeed: (random.nextDouble() - 0.5) * 2,
      ));
    }
  }

  @override
  CustomPainter createPainter({
    required double progress,
    required Color color,
    required Size size,
  }) {
    return _RisingPagesPainter(
      pages: _pages,
      progress: progress,
      color: color,
    );
  }
}

class _RisingPagesPainter extends CustomPainter {
  final List<_PageParticle> pages;
  final double progress;
  final Color color;

  _RisingPagesPainter({
    required this.pages,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final page in pages) {
      // Vertical position: rises from bottom to top, wraps around
      final pageProgress = (progress * page.speed + page.startY) % 1.0;
      final y = center.dy + 150 - pageProgress * 300;

      // Horizontal sway
      final x = center.dx + page.xOffset +
          sin(progress * 2 * pi * page.swayFreq) * page.swayAmp;

      // Fade: fully visible in middle, fading at edges
      final distFromCenter = (pageProgress - 0.5).abs() * 2;
      final alpha = page.opacity * (1.0 - distFromCenter * 0.7);

      if (alpha > 0.05) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(sin(progress * 2 * pi * page.rotSpeed) * 0.3);

        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: page.width,
            height: page.height,
          ),
          const Radius.circular(1),
        );

        // Warm glow
        final glowPaint = Paint()
          ..color = color.withAlpha((alpha * 50).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawRRect(rect.inflate(2), glowPaint);

        // Page surface
        final pagePaint = Paint()
          ..color = Colors.white.withAlpha((alpha * 200).toInt());
        canvas.drawRRect(rect, pagePaint);

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_RisingPagesPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
// 3. NEBULA — Cyberneom (c)
// Logarithmic spiral stardust with cosmic glow connections
// ═══════════════════════════════════════════════════════════════════

class _StarParticle {
  final double angle;
  final double orbitRadius;
  final double speed;
  final double size;
  final double opacity;
  final double spiralRate;

  _StarParticle({
    required this.angle,
    required this.orbitRadius,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.spiralRate,
  });
}

class NebulaDelegate extends SplashAnimationDelegate {
  final List<_StarParticle> _stars = [];

  @override
  Duration get cycleDuration => const Duration(seconds: 8);

  @override
  void initialize(Random random) {
    for (int i = 0; i < 22; i++) {
      final layer = i < 10 ? 0 : (i < 18 ? 1 : 2); // dust, stars, bright
      _stars.add(_StarParticle(
        angle: random.nextDouble() * 2 * pi,
        orbitRadius: 50 + random.nextDouble() * 100,
        speed: 0.2 + random.nextDouble() * 0.5,
        size: layer == 0
            ? 1 + random.nextDouble()
            : (layer == 1 ? 2 + random.nextDouble() * 2 : 4 + random.nextDouble() * 2),
        opacity: layer == 0 ? 0.4 : (layer == 1 ? 0.7 : 1.0),
        spiralRate: 0.3 + random.nextDouble() * 0.7,
      ));
    }
  }

  @override
  CustomPainter createPainter({
    required double progress,
    required Color color,
    required Size size,
  }) {
    return _NebulaPainter(
      stars: _stars,
      progress: progress,
      color: color,
    );
  }
}

class _NebulaPainter extends CustomPainter {
  final List<_StarParticle> stars;
  final double progress;
  final Color color;

  _NebulaPainter({
    required this.stars,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final positions = <Offset>[];

    for (final star in stars) {
      // Logarithmic spiral: radius grows with angle progression
      final spiralAngle = star.angle + progress * 2 * pi * star.speed;
      final spiralRadius = star.orbitRadius *
          (0.7 + 0.3 * sin(progress * 2 * pi * star.spiralRate));
      final wobble = sin(spiralAngle * 3 + progress * pi) * 8;

      final x = center.dx + cos(spiralAngle) * (spiralRadius + wobble);
      final y = center.dy + sin(spiralAngle) * (spiralRadius + wobble);
      final pos = Offset(x, y);
      positions.add(pos);

      // Star glow
      final glowPaint = Paint()
        ..color = color.withAlpha((star.opacity * 60).toInt())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.size * 2);
      canvas.drawCircle(pos, star.size * 2.5, glowPaint);

      // Star core
      final corePaint = Paint()
        ..color = Colors.white.withAlpha((star.opacity * 220).toInt());
      canvas.drawCircle(pos, star.size, corePaint);
    }

    // Faint connections between nearby stars (cosmic web effect)
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final dist = (positions[i] - positions[j]).distance;
        if (dist < 60) {
          final connAlpha = (1.0 - dist / 60) * 0.12;
          final connPaint = Paint()
            ..color = color.withAlpha((connAlpha * 255).toInt())
            ..strokeWidth = 0.5;
          canvas.drawLine(positions[i], positions[j], connPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_NebulaPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
// 4. DIGITAL PULSE — Srznik (d)
// Geometric pulse rings expanding from center + sequentially glowing dots
// ═══════════════════════════════════════════════════════════════════

class _PulseRing {
  final double phase;
  final double maxRadius;

  _PulseRing({required this.phase, required this.maxRadius});
}

class _GridDot {
  final double angle;
  final double radius;
  final double delay;

  _GridDot({
    required this.angle,
    required this.radius,
    required this.delay,
  });
}

class DigitalPulseDelegate extends SplashAnimationDelegate {
  final List<_PulseRing> _rings = [];
  final List<_GridDot> _dots = [];

  @override
  Duration get cycleDuration => const Duration(milliseconds: 2500);

  @override
  void initialize(Random random) {
    // 4 expanding rings
    for (int i = 0; i < 4; i++) {
      _rings.add(_PulseRing(
        phase: i * 0.25,
        maxRadius: 150 + random.nextDouble() * 30,
      ));
    }
    // 12 grid dots in circular pattern
    for (int i = 0; i < 12; i++) {
      _dots.add(_GridDot(
        angle: (i / 12) * 2 * pi,
        radius: 80 + (i % 3) * 30.0,
        delay: i * 0.08,
      ));
    }
  }

  @override
  CustomPainter createPainter({
    required double progress,
    required Color color,
    required Size size,
  }) {
    return _DigitalPulsePainter(
      rings: _rings,
      dots: _dots,
      progress: progress,
      color: color,
    );
  }
}

class _DigitalPulsePainter extends CustomPainter {
  final List<_PulseRing> rings;
  final List<_GridDot> dots;
  final double progress;
  final Color color;

  _DigitalPulsePainter({
    required this.rings,
    required this.dots,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw expanding pulse rings
    for (final ring in rings) {
      final ringProgress = (progress + ring.phase) % 1.0;
      final radius = ringProgress * ring.maxRadius;
      final alpha = (1.0 - ringProgress) * 0.5;

      if (alpha > 0.02) {
        final ringPaint = Paint()
          ..color = Colors.white.withAlpha((alpha * 150).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(center, radius, ringPaint);

        // Faint glow
        final glowPaint = Paint()
          ..color = color.withAlpha((alpha * 40).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(center, radius, glowPaint);
      }
    }

    // Draw grid dots that glow when a ring passes through
    for (final dot in dots) {
      final dx = center.dx + cos(dot.angle) * dot.radius;
      final dy = center.dy + sin(dot.angle) * dot.radius;

      // Check if any ring is near this dot
      double maxGlow = 0;
      for (final ring in rings) {
        final ringProgress = (progress + ring.phase) % 1.0;
        final ringRadius = ringProgress * ring.maxRadius;
        final dist = (ringRadius - dot.radius).abs();
        if (dist < 20) {
          maxGlow = max(maxGlow, 1.0 - dist / 20);
        }
      }

      // Sequential pulse fallback (when no ring passes)
      final sequencePulse = sin((progress + dot.delay) * 2 * pi) * 0.5 + 0.5;
      final dotAlpha = max(maxGlow, sequencePulse * 0.3);

      // Glow
      if (dotAlpha > 0.1) {
        final glowPaint = Paint()
          ..color = color.withAlpha((dotAlpha * 100).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawCircle(Offset(dx, dy), 5, glowPaint);
      }

      // Core dot
      final dotPaint = Paint()
        ..color = Colors.white.withAlpha((0.3 + dotAlpha * 0.7).clamp(0, 1).toInt() * 255);
      canvas.drawCircle(Offset(dx, dy), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_DigitalPulsePainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
// 5. BREATHING CIRCLE — neom_app_lite (o)
// Single large pulsing circle + minimal orbiting particles
// ═══════════════════════════════════════════════════════════════════

class _BreathDot {
  final double angle;
  final double distance;
  final double size;
  final double speed;

  _BreathDot({
    required this.angle,
    required this.distance,
    required this.size,
    required this.speed,
  });
}

class BreathingCircleDelegate extends SplashAnimationDelegate {
  final List<_BreathDot> _dots = [];

  @override
  Duration get cycleDuration => const Duration(seconds: 4);

  @override
  void initialize(Random random) {
    for (int i = 0; i < 6; i++) {
      _dots.add(_BreathDot(
        angle: (i / 6) * 2 * pi + random.nextDouble() * 0.3,
        distance: 85 + random.nextDouble() * 15,
        size: 2 + random.nextDouble() * 2,
        speed: 0.3 + random.nextDouble() * 0.3,
      ));
    }
  }

  @override
  CustomPainter createPainter({
    required double progress,
    required Color color,
    required Size size,
  }) {
    return _BreathingCirclePainter(
      dots: _dots,
      progress: progress,
      color: color,
    );
  }
}

class _BreathingCirclePainter extends CustomPainter {
  final List<_BreathDot> dots;
  final double progress;
  final Color color;

  _BreathingCirclePainter({
    required this.dots,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Breathing scale: 0.85 → 1.15 with easeInOut feel
    final breathPhase = sin(progress * 2 * pi) * 0.5 + 0.5;
    final scale = 0.85 + breathPhase * 0.30;
    final baseRadius = 80 * scale;

    // Radial gradient circle
    final gradient = RadialGradient(
      colors: [
        color.withAlpha((breathPhase * 40 + 15).toInt()),
        color.withAlpha((breathPhase * 20).toInt()),
        Colors.transparent,
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final circlePaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: baseRadius * 1.5),
      );
    canvas.drawCircle(center, baseRadius * 1.5, circlePaint);

    // Soft edge ring
    final edgePaint = Paint()
      ..color = Colors.white.withAlpha((breathPhase * 40 + 20).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, baseRadius, edgePaint);

    // Orbiting dots at edge
    for (final dot in dots) {
      final dotAngle = dot.angle + progress * 2 * pi * dot.speed;
      final dotRadius = dot.distance * scale;
      final x = center.dx + cos(dotAngle) * dotRadius;
      final y = center.dy + sin(dotAngle) * dotRadius;

      final dotAlpha = 0.4 + breathPhase * 0.4;

      final glowPaint = Paint()
        ..color = color.withAlpha((dotAlpha * 60).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), dot.size * 2, glowPaint);

      final corePaint = Paint()
        ..color = Colors.white.withAlpha((dotAlpha * 200).toInt());
      canvas.drawCircle(Offset(x, y), dot.size, corePaint);
    }
  }

  @override
  bool shouldRepaint(_BreathingCirclePainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
// 6. ORBITING PARTICLES — Default / Fallback
// Original animation: particles orbiting in circles with glow
// ═══════════════════════════════════════════════════════════════════

class _OrbitParticle {
  final double angle;
  final double radius;
  final double speed;
  final double size;
  final double opacity;
  final double drift;

  _OrbitParticle({
    required this.angle,
    required this.radius,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.drift,
  });
}

class OrbitingParticlesDelegate extends SplashAnimationDelegate {
  final List<_OrbitParticle> _particles = [];

  @override
  Duration get cycleDuration => const Duration(seconds: 6);

  @override
  void initialize(Random random) {
    for (int i = 0; i < 18; i++) {
      _particles.add(_OrbitParticle(
        angle: random.nextDouble() * 2 * pi,
        radius: 80 + random.nextDouble() * 80,
        speed: 0.3 + random.nextDouble() * 0.7,
        size: 2 + random.nextDouble() * 4,
        opacity: 0.3 + random.nextDouble() * 0.7,
        drift: random.nextDouble() * 20 - 10,
      ));
    }
  }

  @override
  CustomPainter createPainter({
    required double progress,
    required Color color,
    required Size size,
  }) {
    return _OrbitingParticlesPainter(
      particles: _particles,
      progress: progress,
      color: color,
    );
  }
}

class _OrbitingParticlesPainter extends CustomPainter {
  final List<_OrbitParticle> particles;
  final double progress;
  final Color color;

  _OrbitingParticlesPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      final currentAngle = p.angle + (progress * 2 * pi * p.speed);
      final x = center.dx +
          cos(currentAngle) * p.radius +
          sin(progress * pi * 3) * p.drift;
      final y = center.dy +
          sin(currentAngle) * p.radius +
          cos(progress * pi * 2) * p.drift;

      // Glow
      final glowPaint = Paint()
        ..color = color.withAlpha((p.opacity * 80).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(x, y), p.size * 2, glowPaint);

      // Core
      final corePaint = Paint()
        ..color = Colors.white.withAlpha((p.opacity * 220).toInt());
      canvas.drawCircle(Offset(x, y), p.size, corePaint);
    }
  }

  @override
  bool shouldRepaint(_OrbitingParticlesPainter old) => old.progress != progress;
}
