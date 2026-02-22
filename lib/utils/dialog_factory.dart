import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sint/sint.dart';

import '../ui/theme/app_color.dart';

/// Factory for creating consistent dialogs across the core.
/// Eliminates code duplication for common dialog patterns.
///
/// Usage:
/// ```dart
/// // Dropdown selection dialog
/// DialogFactory.showDropdownDialog<ProfileType>(
///   context: context,
///   title: 'Select Profile Type',
///   items: ProfileType.values,
///   selectedValue: currentType,
///   itemBuilder: (type) => type.name,
///   onConfirm: (type) => updateProfileType(type),
/// );
///
/// // Confirmation dialog
/// DialogFactory.showConfirmDialog(
///   context: context,
///   title: 'Delete Item',
///   message: 'Are you sure?',
///   confirmText: 'Delete',
///   onConfirm: () => deleteItem(),
/// );
/// ```
class DialogFactory {
  DialogFactory._();

  /// Adaptive show: uses showDialog on web, showModalBottomSheet on mobile.
  static Future<T?> _showAdaptive<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool isScrollControlled = true,
  }) {
    if (kIsWeb) {
      return showDialog<T>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: builder(ctx),
          ),
        ),
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: builder,
    );
  }

  /// Shows a dropdown selection dialog with confirm/cancel buttons.
  static Future<T?> showDropdownDialog<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required T selectedValue,
    required String Function(T) itemBuilder,
    required void Function(T) onConfirm,
    String? subtitle,
    String confirmText = 'Update',
    String cancelText = 'Cancel',
    bool dismissOnConfirm = true,
    List<T>? excludeItems,
  }) async {
    T currentSelection = selectedValue;
    final filteredItems = excludeItems != null
        ? items.where((item) => !excludeItems.contains(item)).toList()
        : items;

    return _showAdaptive<T>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return _DialogContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _DialogHeader(title: title, subtitle: subtitle),
                const SizedBox(height: 16),

                // Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: DropdownButton<T>(
                    value: currentSelection,
                    isExpanded: true,
                    dropdownColor: AppColor.main75,
                    underline: const SizedBox.shrink(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    items: filteredItems.map((item) {
                      return DropdownMenuItem<T>(
                        value: item,
                        child: Text(itemBuilder(item).capitalize),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        HapticFeedback.selectionClick();
                        setState(() => currentSelection = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                _DialogButtons(
                  confirmText: confirmText,
                  cancelText: cancelText,
                  onConfirm: () {
                    HapticFeedback.lightImpact();
                    onConfirm(currentSelection);
                    if (dismissOnConfirm) Navigator.pop(context, currentSelection);
                  },
                  onCancel: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shows a confirmation dialog with optional message.
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    String? message,
    String? secondaryMessage,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final result = await _showAdaptive<bool>(
      context: context,
      builder: (context) => _DialogContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            if (icon != null) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (isDestructive ? Colors.red : AppColor.bondiBlue75)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? Colors.red[400] : AppColor.bondiBlue75,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            // Messages
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (secondaryMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                secondaryMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),

            // Buttons
            _DialogButtons(
              confirmText: confirmText,
              cancelText: cancelText,
              isDestructive: isDestructive,
              onConfirm: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, true);
              },
              onCancel: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  /// Shows an input dialog with text field.
  static Future<String?> showInputDialog({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? initialValue,
    String? hintText,
    String confirmText = 'Save',
    String cancelText = 'Cancel',
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) async {
    final controller = TextEditingController(text: initialValue);

    return _showAdaptive<String>(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _DialogContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DialogHeader(title: title, subtitle: subtitle),
              const SizedBox(height: 16),

              // Text field
              TextField(
                controller: controller,
                maxLines: maxLines,
                maxLength: maxLength,
                keyboardType: keyboardType,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColor.bondiBlue75),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              _DialogButtons(
                confirmText: confirmText,
                cancelText: cancelText,
                onConfirm: () {
                  final value = controller.text.trim();
                  if (validator != null) {
                    final error = validator(value);
                    if (error != null) {
                      // Show error - could use snackbar
                      return;
                    }
                  }
                  HapticFeedback.lightImpact();
                  Navigator.pop(context, value);
                },
                onCancel: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a loading dialog that can be dismissed programmatically.
  static Future<void> showLoadingDialog({
    required BuildContext context,
    String? message,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColor.main50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dismisses any open dialog.
  static void dismissDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}

/// Container wrapper for bottom sheet dialogs
class _DialogContainer extends StatelessWidget {
  final Widget child;

  const _DialogContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColor.main50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: child,
      ),
    );
  }
}

/// Header for dialogs with title and optional subtitle
class _DialogHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _DialogHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Drag handle (mobile only)
        if (!kIsWeb) ...[
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Button row for dialogs
class _DialogButtons extends StatelessWidget {
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isDestructive;

  const _DialogButtons({
    required this.confirmText,
    required this.cancelText,
    required this.onConfirm,
    required this.onCancel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Text(
              cancelText,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextButton(
            onPressed: onConfirm,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor:
                  isDestructive ? Colors.red[400] : AppColor.bondiBlue75,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
