import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WebHoverCard extends StatefulWidget {

  final Widget? child;
  final Widget Function(bool isHovered)? builder;
  final VoidCallback? onTap;
  final void Function(TapDownDetails)? onSecondaryTapDown;
  final BorderRadius? borderRadius;
  final Color? hoverColor;
  final String? tooltip;
  final EdgeInsets? padding;

  const WebHoverCard({
    super.key,
    this.child,
    this.builder,
    this.onTap,
    this.onSecondaryTapDown,
    this.borderRadius,
    this.hoverColor,
    this.tooltip,
    this.padding,
  }) : assert(child != null || builder != null);

  @override
  State<WebHoverCard> createState() => _WebHoverCardState();
}

class _WebHoverCardState extends State<WebHoverCard> {

  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isHovered = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: widget.onSecondaryTapDown,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.hoverColor ?? Colors.white.withAlpha(18))
                : Colors.transparent,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
          ),
          child: widget.builder != null
              ? widget.builder!(_isHovered)
              : widget.child,
        ),
      ),
    );

    if (widget.tooltip != null) {
      content = Tooltip(
        message: widget.tooltip!,
        child: content,
      );
    }

    return content;
  }
}
