import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_color.dart';

/// Enhanced submit button with loading states, animations, and haptic feedback.
///
/// Features:
/// - Scale animation on press
/// - Gradient background with disabled state
/// - Smooth loading transition
/// - Haptic feedback
/// - Success/error state support
///
/// Usage:
/// ```dart
/// SubmitButton(
///   context,
///   text: 'Submit',
///   onPressed: () => handleSubmit(),
///   isLoading: isSubmitting,
/// )
/// ```
class SubmitButton extends StatefulWidget {
  final String text;
  final Function()? onPressed;
  final bool isEnabled;
  final bool isLoading;
  final double? width;
  final double height;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showSuccessState;
  final bool showErrorState;

  const SubmitButton(
    BuildContext context, {
    super.key,
    this.text = "",
    this.onPressed,
    this.isEnabled = true,
    this.isLoading = false,
    this.width,
    this.height = 50,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.showSuccessState = false,
    this.showErrorState = false,
  });

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
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

  void _onTapDown(TapDownDetails details) {
    if (_canPress) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  void _onTap() {
    if (_canPress && widget.onPressed != null) {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    }
  }

  bool get _canPress =>
      widget.isEnabled && !widget.isLoading && !widget.showSuccessState;

  Color get _backgroundColor {
    if (widget.showSuccessState) return Colors.green;
    if (widget.showErrorState) return Colors.red[400]!;
    if (!widget.isEnabled || widget.isLoading) {
      return (widget.backgroundColor ?? AppColor.bondiBlue75).withValues(alpha: 0.5);
    }
    return widget.backgroundColor ?? AppColor.bondiBlue75;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _canPress
                ? [
                    BoxShadow(
                      color: _backgroundColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return SizedBox(
        key: const ValueKey('loading'),
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(
            widget.textColor ?? Colors.white,
          ),
        ),
      );
    }

    if (widget.showSuccessState) {
      return Icon(
        Icons.check_rounded,
        key: const ValueKey('success'),
        color: widget.textColor ?? Colors.white,
        size: 28,
      );
    }

    if (widget.showErrorState) {
      return Icon(
        Icons.close_rounded,
        key: const ValueKey('error'),
        color: widget.textColor ?? Colors.white,
        size: 28,
      );
    }

    return Row(
      key: const ValueKey('text'),
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            color: widget.textColor ?? Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: TextStyle(
            color: widget.textColor ?? Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

/// Pill-style action button for secondary actions
class ActionPillButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isSelected;
  final Color? selectedColor;

  const ActionPillButton({
    required this.text,
    this.icon,
    this.onPressed,
    this.isSelected = false,
    this.selectedColor,
    super.key,
  });

  @override
  State<ActionPillButton> createState() => _ActionPillButtonState();
}

class _ActionPillButtonState extends State<ActionPillButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = widget.selectedColor ?? AppColor.bondiBlue75;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onPressed?.call();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? selectedColor
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected
                      ? selectedColor
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 18,
                      color: widget.isSelected ? Colors.white : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: widget.isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
