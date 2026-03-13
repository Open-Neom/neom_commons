import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sint/sint.dart';

import 'web_command_palette.dart';
import 'web_shortcuts_help.dart';

/// Data class describing a registered shortcut for help display.
class WebShortcutEntry {
  final List<String> keyLabels;
  final String description;
  final String category;

  const WebShortcutEntry({
    required this.keyLabels,
    required this.description,
    required this.category,
  });
}

/// Keyboard manager widget that wraps a page's Scaffold providing:
/// - Global shortcuts (Ctrl+K command palette, ? shortcuts help, Escape)
/// - Page-specific shortcuts with text field guard
class WebKeyboardManager extends StatefulWidget {
  final String pageId;
  final Map<ShortcutActivator, VoidCallback> pageShortcuts;
  final Widget child;

  const WebKeyboardManager({
    required this.pageId,
    this.pageShortcuts = const {},
    required this.child,
    super.key,
  });

  @override
  State<WebKeyboardManager> createState() => _WebKeyboardManagerState();
}

class _WebKeyboardManagerState extends State<WebKeyboardManager> {

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final hasModifier = isCtrl || isMeta;
    final inTextField = _isInTextField(node);

    // Global: Ctrl+K / Meta+K → Command Palette
    if (key == LogicalKeyboardKey.keyK && hasModifier) {
      WebCommandPalette.show(context);
      return KeyEventResult.handled;
    }

    // Global: Shift+/ (= ?) → Shortcuts Help
    if (key == LogicalKeyboardKey.slash && isShift && !inTextField) {
      _showShortcutsHelp();
      return KeyEventResult.handled;
    }

    // Global: Escape → cascade close
    if (key == LogicalKeyboardKey.escape) {
      // Try page-level escape first (from pageShortcuts)
      final escapeActivator = widget.pageShortcuts.keys.whereType<SingleActivator>().where(
        (a) => a.trigger == LogicalKeyboardKey.escape,
      );
      if (escapeActivator.isNotEmpty) {
        widget.pageShortcuts[escapeActivator.first]?.call();
        return KeyEventResult.handled;
      }
      Sint.back();
      return KeyEventResult.handled;
    }

    // Text field guard: if in text field, only allow modifier-based shortcuts
    if (inTextField && !hasModifier) {
      return KeyEventResult.ignored;
    }

    // Page-specific shortcuts
    for (final entry in widget.pageShortcuts.entries) {
      if (_matchesActivator(entry.key, key, isCtrl, isMeta, isShift)) {
        entry.value();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  bool _isInTextField(FocusNode node) {
    // Check the primary focus node (the one actually focused), not just
    // the manager's own node.  This catches text fields anywhere in the
    // tree, including overlays like the Itzli chat bubble.
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus != node) {
      final pfContext = primaryFocus.context;
      if (pfContext != null) {
        bool found = false;
        pfContext.visitAncestorElements((element) {
          if (element.widget is EditableText) {
            found = true;
            return false;
          }
          return true;
        });
        if (found) return true;
      }
    }

    // Fallback: check the manager node's own ancestors
    final context = node.context;
    if (context == null) return false;
    bool found = false;
    context.visitAncestorElements((element) {
      if (element.widget is EditableText) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }

  bool _matchesActivator(
    ShortcutActivator activator,
    LogicalKeyboardKey key,
    bool isCtrl,
    bool isMeta,
    bool isShift,
  ) {
    if (activator is SingleActivator) {
      if (activator.trigger != key) return false;
      if (activator.control != isCtrl) return false;
      if (activator.meta != isMeta) return false;
      if (activator.shift != isShift) return false;
      return true;
    }
    return false;
  }

  void _showShortcutsHelp() {
    final items = _buildHelpItems();
    WebShortcutsHelp.show(context, items);
  }

  List<ShortcutHelpItem> _buildHelpItems() {
    final items = <ShortcutHelpItem>[];

    // Global shortcuts
    items.addAll([
      const ShortcutHelpItem(keys: ['Ctrl', 'K'], description: 'Command palette', category: 'Global'),
      const ShortcutHelpItem(keys: ['?'], description: 'Keyboard shortcuts', category: 'Global'),
      const ShortcutHelpItem(keys: ['Esc'], description: 'Close / Go back', category: 'Global'),
    ]);

    // Page-specific shortcuts
    for (final entry in widget.pageShortcuts.entries) {
      if (entry.key is SingleActivator) {
        final activator = entry.key as SingleActivator;
        final labels = <String>[];
        if (activator.control) labels.add('Ctrl');
        if (activator.meta) labels.add('Cmd');
        if (activator.shift) labels.add('Shift');
        labels.add(_keyLabel(activator.trigger));

        // Get description from registered entries
        final desc = _shortcutDescriptions[activator.trigger.keyLabel] ?? activator.trigger.keyLabel;
        items.add(ShortcutHelpItem(
          keys: labels,
          description: desc,
          category: 'Page',
        ));
      }
    }

    return items;
  }

  String _keyLabel(LogicalKeyboardKey key) {
    const labels = {
      'Arrow Up': '\u2191',
      'Arrow Down': '\u2193',
      'Arrow Left': '\u2190',
      'Arrow Right': '\u2192',
      'Enter': 'Enter',
      'Escape': 'Esc',
      'Tab': 'Tab',
      'Space': 'Space',
      'Slash': '/',
      'Backspace': '\u232B',
    };
    return labels[key.keyLabel] ?? key.keyLabel;
  }

  /// Page-specific shortcut descriptions by key label.
  Map<String, String> get _shortcutDescriptions {
    switch (widget.pageId) {
      case 'home':
        return {'N': 'Notifications', 'S': 'Search'};
      case 'inbox':
        return {'Arrow Up': 'Previous conversation', 'Arrow Down': 'Next conversation', 'Enter': 'Open conversation'};
      case 'events':
        return {'N': 'Create event'};
      case 'search':
        return {'Slash': 'Focus search', 'Tab': 'Cycle filters'};
      case 'settings':
        return {'Arrow Up': 'Previous section', 'Arrow Down': 'Next section'};
      case 'profile':
        return {'E': 'Edit profile'};
      case 'postDetails':
        return {'L': 'Like post'};
      default:
        return {};
    }
  }
}
