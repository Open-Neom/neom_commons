import 'package:get/get.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
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
      name: AppRouteConstants.accountRemove,
      page: () => const SplashPage(),
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
  ];

}
