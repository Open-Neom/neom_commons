import 'package:flutter/material.dart';

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  const BreadcrumbItem({
    required this.label,
    this.onTap,
    this.icon,
  });
}

class WebBreadcrumb extends StatelessWidget {

  final List<BreadcrumbItem> items;

  const WebBreadcrumb({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.white.withAlpha(80),
                ),
              ),
            _BreadcrumbChip(
              item: items[i],
              isLast: i == items.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbChip extends StatefulWidget {
  final BreadcrumbItem item;
  final bool isLast;

  const _BreadcrumbChip({required this.item, required this.isLast});

  @override
  State<_BreadcrumbChip> createState() => _BreadcrumbChipState();
}

class _BreadcrumbChipState extends State<_BreadcrumbChip> {

  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isClickable = !widget.isLast && widget.item.onTap != null;
    final color = widget.isLast
        ? Colors.white
        : Colors.white.withAlpha(isClickable && _isHovered ? 220 : 120);

    Widget label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.item.icon != null) ...[
          Icon(widget.item.icon, size: 14, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          widget.item.label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: widget.isLast ? FontWeight.w600 : FontWeight.w400,
            decoration: _isHovered && isClickable
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: color,
          ),
        ),
      ],
    );

    if (!isClickable) return label;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.item.onTap,
        child: label,
      ),
    );
  }
}
