import 'package:get/get.dart';
import 'package:neom_core/core/utils/constants/app_route_constants.dart';
import '../analytics/ui/analytics_page.dart';
import '../media/media_fullscreen_page.dart';
import 'ui/previous_version_page.dart';
import 'ui/splash_page.dart';
import 'ui/under_construction_page.dart';

class CommonRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.splashScreen,
        page: () => const SplashPage(),
        transition: Transition.zoom
    ),
    GetPage(
        name: AppRouteConstants.introCreating,
        page: () => const SplashPage(),
        transition: Transition.zoom
    ),
    GetPage(
        name: AppRouteConstants.introWelcome,
        page: () => const SplashPage(),
        transition: Transition.zoom
    ),
    GetPage(
      name: AppRouteConstants.accountRemove,
      page: () => const SplashPage(),
    ),
    GetPage(
        name: AppRouteConstants.mediaFullScreen,
        page: () => const MediaFullScreenPage(),
        transition: Transition.zoom
    ),
    GetPage(
      name: AppRouteConstants.previousVersion,
      page: () => const PreviousVersionPage(),
    ),
    GetPage(
      name: AppRouteConstants.underConstruction,
      page: () => const UnderConstructionPage(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRouteConstants.analytics,
      page: () => const AnalyticsPage(),
      transition: Transition.zoom,
    ),
  ];

}
