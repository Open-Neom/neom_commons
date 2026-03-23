import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

import '../../theme/app_color.dart';

/// Data class for a single shortcut help entry.
class ShortcutHelpItem {
  final List<String> keys;
  final String description;
  final String category;

  const ShortcutHelpItem({
    required this.keys,
    required this.description,
    required this.category,
  });
}

/// Dialog showing keyboard shortcuts help, grouped by category.
/// Adapted from rooms KeyboardShortcutsHelp + _KeyBadge pattern.
class WebShortcutsHelp extends StatelessWidget {
  final List<ShortcutHelpItem> shortcuts;

  const WebShortcutsHelp({required this.shortcuts, super.key});

  /// Shows the shortcuts help as a dialog.
  static void show(BuildContext context, List<ShortcutHelpItem> shortcuts) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(120),
      builder: (_) => Center(
        child: WebShortcutsHelp(shortcuts: shortcuts),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ShortcutHelpItem>>{};
    for (final item in shortcuts) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: AppColor.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.keyboard, color: Colors.white70, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Keyboard Shortcuts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Sint.back(),
                    child: const Icon(Icons.close, color: Colors.white54, size: 20),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColor.borderSubtle),
            // Shortcuts list
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final category in grouped.keys) ...[
                      if (grouped.keys.first != category)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: AppColor.borderSubtle),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            color: AppColor.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      for (final item in grouped[category]!)
                        _ShortcutRow(keys: item.keys, description: item.description),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final List<String> keys;
  final String description;

  const _ShortcutRow({required this.keys, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Wrap(
            spacing: 4,
            children: keys.map((key) => _KeyBadge(key)).toList(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withAlpha(204),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyBadge extends StatelessWidget {
  final String keyLabel;

  const _KeyBadge(this.keyLabel);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.surfaceDim,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColor.borderMedium),
      ),
      child: Text(
        keyLabel,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
