import 'package:neom_core/ui/deferred_loader.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import 'ui/previous_version_page.dart' deferred as prevVersion;
import 'ui/splash_page.dart' deferred as splash;
import 'ui/terms_conditions_page.dart' deferred as terms;
import 'ui/under_construction_page.dart' deferred as underConstruction;

class CommonRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
        name: AppRouteConstants.splashScreen,
        page: () => DeferredLoader(splash.loadLibrary, () => splash.SplashPage()),
        transition: Transition.zoom
    ),
    SintPage(
      name: AppRouteConstants.accountRemove,
      page: () => DeferredLoader(splash.loadLibrary, () => splash.SplashPage()),
    ),
    SintPage(
      name: AppRouteConstants.previousVersion,
      page: () => DeferredLoader(prevVersion.loadLibrary, () => prevVersion.PreviousVersionPage()),
    ),
    SintPage(
      name: AppRouteConstants.underConstruction,
      page: () => DeferredLoader(underConstruction.loadLibrary, () => underConstruction.UnderConstructionPage()),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.termsConditions,
      page: () => DeferredLoader(terms.loadLibrary, () => terms.TermsConditionsPage()),
    ),
  ];

}
