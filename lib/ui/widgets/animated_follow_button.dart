import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated follow/unfollow button with heart burst effect.
///
/// Features:
/// - Smooth state transition animation
/// - Heart particles on follow action
/// - Haptic feedback
/// - Loading state support
class AnimatedFollowButton extends StatefulWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final String? followText;
  final String? followingText;
  final String? unfollowText;

  const AnimatedFollowButton({
    required this.isFollowing,
    required this.onPressed,
    this.isLoading = false,
    this.width = 140,
    this.height = 40,
    this.followText,
    this.followingText,
    this.unfollowText,
    super.key,
  });

  @override
  State<AnimatedFollowButton> createState() => _AnimatedFollowButtonState();
}

class _AnimatedFollowButtonState extends State<AnimatedFollowButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _heartBurstController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heartBurstAnimation;

  bool _isHovering = false;
  bool _wasFollowing = false;

  final List<_HeartParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _wasFollowing = widget.isFollowing;

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _heartBurstController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _heartBurstAnimation = CurvedAnimation(
      parent: _heartBurstController,
      curve: Curves.easeOutCubic,
    );

    _heartBurstController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _particles.clear());
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedFollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger heart burst when transitioning from not following to following
    if (widget.isFollowing && !_wasFollowing) {
      _triggerHeartBurst();
    }
    _wasFollowing = widget.isFollowing;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _heartBurstController.dispose();
    super.dispose();
  }

  void _triggerHeartBurst() {
    _particles.clear();
    for (int i = 0; i < 8; i++) {
      _particles.add(_HeartParticle(
        angle: (i * math.pi / 4) + _random.nextDouble() * 0.5,
        distance: 30 + _random.nextDouble() * 20,
        size: 8 + _random.nextDouble() * 6,
        delay: _random.nextDouble() * 0.2,
      ));
    }
    _heartBurstController.forward(from: 0);
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  void _onTap() {
    if (widget.isLoading) return;
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _heartBurstAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Heart particles
                  if (_particles.isNotEmpty)
                    ..._particles.map((particle) => _buildHeartParticle(particle)),
                  // Main button
                  _buildButton(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton() {
    final isFollowing = widget.isFollowing;
    final showUnfollow = isFollowing && _isHovering;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.height / 2),
        gradient: isFollowing
            ? null
            : LinearGradient(
                colors: [
                  Colors.pink[400]!,
                  Colors.purple[400]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isFollowing
            ? (showUnfollow ? Colors.red.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.1))
            : null,
        border: Border.all(
          color: isFollowing
              ? (showUnfollow ? Colors.red.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.3))
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isFollowing
            ? null
            : [
                BoxShadow(
                  color: Colors.pink.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Center(
        child: widget.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    isFollowing ? Colors.white70 : Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isFollowing
                          ? (showUnfollow ? Icons.person_remove_rounded : Icons.check_rounded)
                          : Icons.person_add_rounded,
                      key: ValueKey('icon_${isFollowing}_$showUnfollow'),
                      size: 18,
                      color: isFollowing
                          ? (showUnfollow ? Colors.red[400] : Colors.white70)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _getButtonText(isFollowing, showUnfollow),
                      key: ValueKey('text_${isFollowing}_$showUnfollow'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isFollowing
                            ? (showUnfollow ? Colors.red[400] : Colors.white70)
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _getButtonText(bool isFollowing, bool showUnfollow) {
    if (isFollowing) {
      return showUnfollow
          ? (widget.unfollowText ?? 'Unfollow')
          : (widget.followingText ?? 'Following');
    }
    return widget.followText ?? 'Follow';
  }

  Widget _buildHeartParticle(_HeartParticle particle) {
    final progress = (_heartBurstAnimation.value - particle.delay).clamp(0.0, 1.0);
    if (progress <= 0) return const SizedBox.shrink();

    final distance = particle.distance * progress;
    final opacity = 1.0 - progress;
    final scale = 1.0 - (progress * 0.5);

    final dx = math.cos(particle.angle) * distance;
    final dy = math.sin(particle.angle) * distance;

    return Positioned(
      left: widget.width / 2 - particle.size / 2 + dx,
      top: widget.height / 2 - particle.size / 2 + dy,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Icon(
            Icons.favorite,
            size: particle.size,
            color: Colors.pink[400],
          ),
        ),
      ),
    );
  }
}

class _HeartParticle {
  final double angle;
  final double distance;
  final double size;
  final double delay;

  _HeartParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
  });
}

/// Simplified animated message button that matches the follow button style
class AnimatedMessageButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double width;
  final double height;
  final String? text;

  const AnimatedMessageButton({
    required this.onPressed,
    this.width = 140,
    this.height = 40,
    this.text,
    super.key,
  });

  @override
  State<AnimatedMessageButton> createState() => _AnimatedMessageButtonState();
}

class _AnimatedMessageButtonState extends State<AnimatedMessageButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onPressed();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.text ?? 'Message',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
