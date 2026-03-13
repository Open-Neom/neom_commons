import 'package:flutter/material.dart';

import 'web_hover_card.dart';

class WebActionButton {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  const WebActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
  });
}

class WebActionBar extends StatelessWidget {

  final String title;
  final String? subtitle;
  final List<WebActionButton> actions;

  const WebActionBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withAlpha(120),
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ...actions.map(_buildButton),
        ],
      ),
    );
  }

  Widget _buildButton(WebActionButton action) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: WebHoverCard(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: action.isPrimary
            ? Colors.white.withAlpha(30)
            : Colors.white.withAlpha(18),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              size: 18,
              color: action.isPrimary ? Colors.white : Colors.white.withAlpha(180),
            ),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: TextStyle(
                color: action.isPrimary ? Colors.white : Colors.white.withAlpha(180),
                fontSize: 13,
                fontWeight: action.isPrimary ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
