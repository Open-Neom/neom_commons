
import 'package:flutter/material.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

class AppColor {

  static const Color appBlack = Color.fromRGBO(41,41,43, 1);

  static Color getMain() {
    AppInUse appInUse = AppConfig.instance.appInUse;
    Color mainColor = Colors.white;
    switch(appInUse) {
      case AppInUse.c:
        mainColor = const Color.fromRGBO(110, 40, 140, 1);
        break;
      case AppInUse.d:
        mainColor = const Color(0xFF071e33);
        break;
      case AppInUse.e:
        mainColor = const Color.fromRGBO(140, 20, 25, 1);
        /// mainColor = const Color.fromRGBO(175, 40, 30, 1);
        /// mainColor = const Color.fromRGBO(156, 48, 26, 1);
        break;
      case AppInUse.g:
        mainColor = const Color.fromRGBO(35, 68, 165, 1);
        break;
      case AppInUse.o:
        mainColor = const Color.fromRGBO(110, 40, 140, 1);
        break;
      case AppInUse.i:
        mainColor = const Color.fromRGBO(28, 50, 55, 1);
        break;
      default:
        mainColor = const Color.fromRGBO(110, 40, 140, 1);
    }

    return mainColor;
  }

  /// Returns the brand color for a given [AppInUse], regardless of the
  /// currently running app.  Useful for cross-promo cards that must display
  /// the *source* app's colour.
  static Color getColorForApp(AppInUse appInUse) {
    switch (appInUse) {
      case AppInUse.c:
        return const Color.fromRGBO(110, 40, 140, 1);
      case AppInUse.d:
        return const Color(0xFF071e33);
      case AppInUse.e:
        return const Color.fromRGBO(140, 20, 25, 1);
      case AppInUse.g:
        return const Color.fromRGBO(35, 68, 165, 1);
      case AppInUse.o:
        return const Color.fromRGBO(110, 40, 140, 1);
      case AppInUse.i:
        return const Color.fromRGBO(28, 50, 55, 1);
      default:
        return const Color.fromRGBO(110, 40, 140, 1);
    }
  }

  // ── Deprecated Alpha Variants ───────────────────────────────
  // Use semantic surface getters instead: surfaceDim, surfaceCard,
  // surfaceElevated, surfaceBright. These produce consistent opaque
  // colors via Color.lerp, unlike withAlpha which renders differently
  // on web vs native.
  @Deprecated('Use AppColor.surfaceDim instead')
  static Color main25 = getMain().withAlpha(64);
  @Deprecated('Use AppColor.surfaceCard instead')
  static Color main50 = getMain().withAlpha(128);
  @Deprecated('Use AppColor.surfaceElevated instead')
  static Color main75 = getMain().withAlpha(191);
  @Deprecated('Use AppColor.surfaceBright instead')
  static Color main95 = getMain().withAlpha(242);
  @Deprecated('Use AppColor.surfaceElevated instead')
  static final Color bottomNavigationBar = getMain().withAlpha(128);
  @Deprecated('Use AppColor.surfaceCard instead')
  static final Color messageComposer = getMain().withAlpha(128);
  @Deprecated('Use AppColor.surfaceCard instead')
  static final Color drawer = getMain().withAlpha(128);
  @Deprecated('Use AppColor.surfaceElevated instead')
  static final Color appBar = getMain().withAlpha(128);
  @Deprecated('Use AppColor.surfaceDim instead')
  static final Color boxDecoration = getMain().withAlpha(77);

  static const Color secondary = Color(0xff14171A);
  static const Color lightGrey = Color(0xffAAB8C2);

  static const Color white = Colors.white;
  static final Color white80 = Colors.white.withAlpha(204);
  static final Color white50 = Colors.white.withAlpha(128);
  static final Color white25 = Colors.white.withAlpha(64);

  static const Color yellow = Color(0xffFCCD00);
  static const Color ceriseRed = Color.fromRGBO(224, 36, 94, 1.0);
  static const Color red = Colors.red;
  static const Color mystic = Color.fromRGBO(230, 236, 240, 1.0);
  static const Color bondiBlue = Color.fromRGBO(50, 100, 215, 1.0);
  static const Color bondiBlue25 = Color.fromRGBO(50, 100, 215, 0.25);
  static const Color bondiBlue50 = Color.fromRGBO(50, 100, 215, 0.50);
  static const Color bondiBlue75 = Color.fromRGBO(50, 100, 215, 0.75);
  static const Color dodgetBlue = Color.fromRGBO(29, 162, 240, 1.0);

  static const Color textColor = Color.fromRGBO(250, 250, 250, 0.95);
  static const Color textButton = Colors.black;
  static const Color cutColoredImage = Color(0xBB8338f4);
  static const Color cardColor = Color.fromRGBO(47, 65, 123, 0.6);

  static Color getContextCardColor(BuildContext context) {
    return Theme.of(context).cardColor.withAlpha(52);
  }

  static const Color blogEditor = Color(0xFF1976D2);

  static const Color darkViolet = Color.fromRGBO(79, 25, 100, 1);
  static Color deepDarkViolet = const Color.fromRGBO(79, 25, 100, 1).withAlpha(156);

  /// Release shelf accent colour per app.
  static Color getReleaseShelfColor() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.e:
        return const Color.fromRGBO(15, 30, 80, 1);
      case AppInUse.g:
        return const Color.fromRGBO(20, 38, 95, 1);
      case AppInUse.c:
      case AppInUse.o:
        return const Color.fromRGBO(180, 90, 20, 1);
      case AppInUse.i:
        return const Color.fromRGBO(18, 35, 38, 1);
      default:
        return bondiBlue75;
    }
  }

  static const Color darkBackground = Color.fromRGBO(20, 20, 20, 1);

  /// Accent color used for primary CTA buttons (login, signup, etc.)
  /// Each app gets its own vibrant accent to match its brand identity.
  static Color getAccentColor() {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.i:
        return const Color(0xFF00FFFF); // Itzli cyan
      case AppInUse.g:
        return const Color.fromRGBO(65, 120, 255, 1); // Gigmeout blue
      case AppInUse.e:
        return const Color.fromRGBO(200, 50, 50, 1); // EMXI red
      case AppInUse.c:
      case AppInUse.o:
        return const Color.fromRGBO(140, 60, 180, 1); // Cyberneom purple
      default:
        return Colors.white;
    }
  }

  // ── Semantic Surface Colors ──────────────────────────────────
  // Dark base tinted with the brand colour — matches Login Web style.
  // Apps with already-dark brand colours (e.g. Gigmeout navy) use a
  // higher tint multiplier so the colour is visible; apps with bright
  // brand colours (e.g. Emxi red) keep the base factor to stay subtle.

  /// Tint multiplier: dark brand colours need stronger lerp to show through.
  static double get _tintMultiplier {
    switch (AppConfig.instance.appInUse) {
      case AppInUse.g:
        return 2.0;
      case AppInUse.i:
        return 2.5;
      default:
        return 1.0;
    }
  }

  static double _t(double base) => (base * _tintMultiplier).clamp(0.0, 1.0);

  /// Primary page/scaffold background.
  static Color get scaffold => Color.lerp(darkBackground, getMain(), _t(0.15))!;

  /// Lowest-elevation surface — subtle panels, input fields.
  static Color get surfaceDim => Color.lerp(darkBackground, getMain(), _t(0.08))!;

  /// Card / tile / container surface.
  static Color get surfaceCard => Color.lerp(darkBackground, getMain(), _t(0.12))!;

  /// Elevated surface — AppBar, dialogs, modals.
  static Color get surfaceElevated => Color.lerp(darkBackground, getMain(), _t(0.20))!;

  /// Highest-elevation accent surface.
  static Color get surfaceBright => Color.lerp(darkBackground, getMain(), _t(0.28))!;

  // ── Semantic Border / Divider ────────────────────────────────
  static final Color borderSubtle = Colors.white.withAlpha(15);
  static final Color borderMedium = Colors.white.withAlpha(30);
  static final Color dividerColor = Colors.white.withAlpha(20);

  // ── Semantic Text Colors ─────────────────────────────────────
  static const Color textPrimary   = Colors.white;
  static final Color textSecondary = Colors.white.withAlpha(180);
  static final Color textTertiary  = Colors.white.withAlpha(120);
  static final Color textMuted     = Colors.white.withAlpha(80);

  // ── Additional White Variants ────────────────────────────────
  static final Color white10 = Colors.white.withAlpha(26);
  static final Color white15 = Colors.white.withAlpha(38);

}
