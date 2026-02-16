import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_core/domain/model/app_profile.dart';

/// Circular progress indicator showing profile completion percentage.
/// Encourages users to complete their profile with actionable tips.
///
/// Features:
/// - Animated circular progress
/// - Percentage display with color coding
/// - Expandable tips section
/// - Tap actions for each incomplete item
class ProfileCompletionIndicator extends StatefulWidget {
  final AppProfile profile;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onCoverTap;
  final VoidCallback? onBioTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onGenresTap;
  final bool showTips;
  final bool compact;

  const ProfileCompletionIndicator({
    required this.profile,
    this.onPhotoTap,
    this.onCoverTap,
    this.onBioTap,
    this.onLocationTap,
    this.onGenresTap,
    this.showTips = true,
    this.compact = false,
    super.key,
  });

  @override
  State<ProfileCompletionIndicator> createState() =>
      _ProfileCompletionIndicatorState();
}

class _ProfileCompletionIndicatorState extends State<ProfileCompletionIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  bool _showingTips = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_CompletionItem> _getCompletionItems() {
    return [
      _CompletionItem(
        label: 'Foto de perfil',
        icon: Icons.camera_alt_rounded,
        isComplete: widget.profile.photoUrl.isNotEmpty,
        onTap: widget.onPhotoTap,
      ),
      _CompletionItem(
        label: 'Imagen de portada',
        icon: Icons.image_rounded,
        isComplete: widget.profile.coverImgUrl.isNotEmpty,
        onTap: widget.onCoverTap,
      ),
      _CompletionItem(
        label: 'Biografía',
        icon: Icons.edit_rounded,
        isComplete: widget.profile.aboutMe.isNotEmpty,
        onTap: widget.onBioTap,
      ),
      _CompletionItem(
        label: 'Ubicación',
        icon: Icons.location_on_rounded,
        isComplete: widget.profile.position != null,
        onTap: widget.onLocationTap,
      ),
    ];
  }

  double _calculateProgress() {
    final items = _getCompletionItems();
    final completed = items.where((i) => i.isComplete).length;
    return completed / items.length;
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.6) return Colors.amber;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final items = _getCompletionItems();
    final incompleteItems = items.where((i) => !i.isComplete).toList();

    // Don't show if profile is complete
    if (progress >= 1.0 && !widget.compact) {
      return _buildCompleteBadge();
    }

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final animatedProgress = progress * _progressAnimation.value;
        final progressColor = _getProgressColor(progress);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: progressColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main indicator row
              GestureDetector(
                onTap: widget.showTips && incompleteItems.isNotEmpty
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _showingTips = !_showingTips);
                      }
                    : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Circular progress
                      SizedBox(
                        width: widget.compact ? 48 : 56,
                        height: widget.compact ? 48 : 56,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background circle
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: 1,
                                strokeWidth: 4,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            // Progress circle
                            SizedBox.expand(
                              child: CustomPaint(
                                painter: _CircularProgressPainter(
                                  progress: animatedProgress,
                                  color: progressColor,
                                  strokeWidth: 4,
                                ),
                              ),
                            ),
                            // Percentage text
                            Text(
                              '${(animatedProgress * 100).round()}%',
                              style: TextStyle(
                                fontSize: widget.compact ? 12 : 14,
                                fontWeight: FontWeight.bold,
                                color: progressColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              progress >= 1.0
                                  ? '¡Perfil completo!'
                                  : 'Completa tu perfil',
                              style: TextStyle(
                                fontSize: widget.compact ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (!widget.compact && incompleteItems.isNotEmpty)
                              Text(
                                '${incompleteItems.length} elemento${incompleteItems.length > 1 ? 's' : ''} pendiente${incompleteItems.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[400],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Expand/collapse indicator
                      if (widget.showTips && incompleteItems.isNotEmpty)
                        AnimatedRotation(
                          turns: _showingTips ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Expandable tips section
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildTipsSection(incompleteItems),
                crossFadeState: _showingTips
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompleteBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green[400],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '¡Perfil completo!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.green[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(List<_CompletionItem> incompleteItems) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 8),
          ...incompleteItems.map((item) => _buildTipItem(item)),
        ],
      ),
    );
  }

  Widget _buildTipItem(_CompletionItem item) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        item.onTap?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                size: 18,
                color: Colors.orange[400],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Agregar ${item.label.toLowerCase()}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionItem {
  final String label;
  final IconData icon;
  final bool isComplete;
  final VoidCallback? onTap;

  _CompletionItem({
    required this.label,
    required this.icon,
    required this.isComplete,
    this.onTap,
  });
}

/// Custom painter for circular progress with rounded caps
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    const startAngle = -math.pi / 2; // Start from top

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
