import 'package:flutter/material.dart';

/// Helper for responsive grid layouts that adapt column count to screen width.
///
/// Usage:
/// ```dart
/// GridView.builder(
///   gridDelegate: WebResponsiveGrid.responsiveDelegate(context),
///   ...
/// )
/// ```
class WebResponsiveGrid {
  WebResponsiveGrid._();

  /// Returns the appropriate column count based on available width.
  static int getColumnCount(
    double width, {
    int mobileColumns = 2,
    int tabletColumns = 3,
    int desktopColumns = 4,
    int wideDesktopColumns = 5,
  }) {
    if (width > 1400) return wideDesktopColumns;
    if (width > 1000) return desktopColumns;
    if (width > 600) return tabletColumns;
    return mobileColumns;
  }

  /// Returns a responsive [SliverGridDelegateWithFixedCrossAxisCount].
  static SliverGridDelegateWithFixedCrossAxisCount responsiveDelegate(
    BuildContext context, {
    int mobileColumns = 2,
    int tabletColumns = 3,
    int desktopColumns = 4,
    int wideDesktopColumns = 5,
    double mainAxisSpacing = 1,
    double crossAxisSpacing = 1,
    double childAspectRatio = 1,
  }) {
    final width = MediaQuery.of(context).size.width;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: getColumnCount(
        width,
        mobileColumns: mobileColumns,
        tabletColumns: tabletColumns,
        desktopColumns: desktopColumns,
        wideDesktopColumns: wideDesktopColumns,
      ),
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
    );
  }
}
