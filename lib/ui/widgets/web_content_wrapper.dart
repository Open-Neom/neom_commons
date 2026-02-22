import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Wraps content with max-width constraints and centering on web.
/// On mobile, returns the child unmodified.
///
/// Usage:
/// ```dart
/// WebContentWrapper(
///   maxWidth: 800,
///   child: MyPageContent(),
/// )
/// ```
class WebContentWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  const WebContentWrapper({
    required this.child,
    this.maxWidth = 680,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
