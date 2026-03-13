import 'package:flutter/material.dart';

import '../../theme/app_color.dart';

class WebThemeConstants {
  WebThemeConstants._();

  static const Duration hoverDuration = Duration(milliseconds: 150);
  static const Duration sidebarDuration = Duration(milliseconds: 200);
  static const Duration transitionDuration = Duration(milliseconds: 300);

  static BorderSide get sidebarBorder =>
      BorderSide(color: AppColor.borderSubtle);

  static BoxDecoration get glassCard => BoxDecoration(
    color: AppColor.surfaceCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColor.borderSubtle),
  );

  static BoxDecoration get panelDecoration => BoxDecoration(
    color: AppColor.surfaceDim,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColor.borderSubtle),
  );

  static Widget fadeSwitch(Widget child, {Key? key}) {
    return AnimatedSwitcher(
      duration: transitionDuration,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: key ?? ValueKey(child.hashCode),
        child: child,
      ),
    );
  }
}
