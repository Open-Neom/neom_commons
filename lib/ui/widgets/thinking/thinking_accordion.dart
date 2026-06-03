import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A premium, glassmorphic accordion widget to visually display active or historical
/// reasoning steps. Features smooth animations, dynamic HSL colors, and elegant layout.
class ThinkingAccordion extends StatefulWidget {
  /// The reasoning text / thoughts to display.
  final String thinkingText;

  /// Whether the model is currently in the active process of thinking.
  final bool isActive;

  /// Optional custom title for the accordion header.
  final String? title;

  const ThinkingAccordion({
    Key? key,
    required this.thinkingText,
    required this.isActive,
    this.title,
  }) : super(key: key);

  @override
  State<ThinkingAccordion> createState() => _ThinkingAccordionState();
}

class _ThinkingAccordionState extends State<ThinkingAccordion>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isActive;

    // Set up smooth pulse animation for active thinking state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ThinkingAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
        setState(() {
          _isExpanded = true;
        });
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.thinkingText.isEmpty && !widget.isActive) {
      return const SizedBox.shrink();
    }

    // Curated high-fidelity color tokens (independent of custom themes for safety)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark
        ? Colors.indigo.withOpacity(0.08)
        : Colors.indigo.withOpacity(0.04);
    final borderColor = isDark
        ? Colors.indigo.withOpacity(0.2)
        : Colors.indigo.withOpacity(0.1);
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(

            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (Clickable toggle)
                InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(16.0),
                    bottom: Radius.circular(_isExpanded ? 0 : 16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        // Dynamic Pulsing Icon / Indicator
                        if (widget.isActive)
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _pulseAnimation.value,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.indigoAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.indigo,
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.teal,
                            size: 16,
                          ),
                        const SizedBox(width: 12),
                        // Title
                        Expanded(
                          child: Text(
                            widget.title ??
                                (widget.isActive
                                    ? 'Procesando razonamiento agéntico...'
                                    : 'Razonamiento estructurado completado'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.indigo[100] : Colors.indigo[900],
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        // Collapse / Expand Arrow Icon
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: isDark ? Colors.white54 : Colors.black45,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                // Animated Expandable Body
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: borderColor.withOpacity(0.5),
                                width: 1.0,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            widget.thinkingText.isEmpty && widget.isActive
                                ? 'Analizando lógica interna...'
                                : widget.thinkingText,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              fontFamily: 'monospace',
                              color: textColor,
                              letterSpacing: 0.1,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
