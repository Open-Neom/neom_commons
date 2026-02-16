import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import 'ui/previous_version_page.dart';
import 'ui/splash_page.dart';
import 'ui/under_construction_page.dart';

class CommonRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
        name: AppRouteConstants.splashScreen,
        page: () => const SplashPage(),
        transition: Transition.zoom
    ),
    SintPage(
      name: AppRouteConstants.accountRemove,
      page: () => const SplashPage(),
    ),
    SintPage(
      name: AppRouteConstants.previousVersion,
      page: () => const PreviousVersionPage(),
    ),
    SintPage(
      name: AppRouteConstants.underConstruction,
      page: () => const UnderConstructionPage(),
      transition: Transition.zoom,
    ),
  ];

}
