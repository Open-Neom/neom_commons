class WebBreakpoints {
  WebBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 1000;
  static const double smallDesktop = 1200;
  static const double desktop = 1400;

  static bool isMobile(double width) => width <= mobile;
  static bool isTablet(double width) => width > mobile && width <= tablet;
  static bool isDesktop(double width) => width > smallDesktop;
  static bool isWideDesktop(double width) => width > desktop;

  static bool sidebarExpanded(double width) => width > desktop;
  static bool showRightPanel(double width) => width > smallDesktop;

  static double sidebarWidth(double width) =>
      sidebarExpanded(width) ? 220.0 : 72.0;

  static int gridColumns(double width, {
    int mobileColumns = 2,
    int tabletColumns = 3,
    int desktopColumns = 4,
    int wideDesktopColumns = 5,
  }) {
    if (width <= mobile) return mobileColumns;
    if (width <= tablet) return tabletColumns;
    if (width <= desktop) return desktopColumns;
    return wideDesktopColumns;
  }
}
