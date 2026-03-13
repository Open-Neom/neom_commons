import 'package:flutter/material.dart';

class WebTooltipButton extends StatefulWidget {

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;
  final int? badge;

  const WebTooltipButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.size = 20,
    this.badge,
  });

  @override
  State<WebTooltipButton> createState() => _WebTooltipButtonState();
}

class _WebTooltipButtonState extends State<WebTooltipButton> {

  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isHovered = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.white.withAlpha(18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  widget.icon,
                  size: widget.size,
                  color: _isHovered
                      ? Colors.white
                      : Colors.white.withAlpha(180),
                ),
                if (widget.badge != null && widget.badge! > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${widget.badge! > 99 ? "99+" : widget.badge}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
