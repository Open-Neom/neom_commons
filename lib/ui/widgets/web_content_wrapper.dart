import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Wraps content with max-width constraints and centering on web/wide screens.
/// On mobile (narrow screens), returns the child unmodified.
///
/// Usage:
/// ```dart
/// // Basic — wraps body Container in Scaffold
/// body: WebContentWrapper(
///   maxWidth: 800,
///   padding: EdgeInsets.zero,
///   child: Container(
///     decoration: AppTheme.appBoxDecoration,
///     child: ListView(...),
///   ),
/// ),
///
/// // With back button (for pages without AppBar)
/// body: WebContentWrapper(
///   maxWidth: 800,
///   showBackButton: true,
///   child: SingleChildScrollView(...),
/// ),
/// ```
class WebContentWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  /// Shows a back button at the top-left on web.
  /// Use for pages that don't have an AppBar.
  final bool showBackButton;

  const WebContentWrapper({
    required this.child,
    this.maxWidth = 680,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.showBackButton = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // On mobile with narrow screen, return child unmodified
    if (!kIsWeb && screenWidth <= 900) return child;

    Widget content = child;

    if (showBackButton) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const BackButton(),
          Expanded(child: child),
        ],
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: content,
        ),
      ),
    );
  }
}
