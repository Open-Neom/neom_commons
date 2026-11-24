import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/ui/splash_controller.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:sint/sint.dart';

class _FakeLoginService extends Fake implements LoginService {
  AuthStatus status = AuthStatus.waiting;
  int signOutCalls = 0;

  @override
  AuthStatus getAuthStatus() => status;

  @override
  void setAuthStatus(AuthStatus newStatus) {
    status = newStatus;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

class _FakeUserService extends Fake implements UserService {
  @override
  AppUser user = AppUser();

  @override
  AppProfile profile = AppProfile();
}

void main() {
  late _FakeLoginService loginService;
  late _FakeUserService userService;

  setUp(() {
    Sint.testMode = true;
    Sint.reset();
    loginService = _FakeLoginService();
    userService = _FakeUserService();
    Sint.put<LoginService>(loginService, permanent: true);
    Sint.put<UserService>(userService, permanent: true);
  });

  tearDown(() {
    Sint.reset();
  });

  testWidgets(
    'embedded SplashController on root `/` stays put while authStatus is waiting',
    (tester) async {
      await tester.pumpWidget(
        SintMaterialApp(
          initialRoute: AppRouteConstants.root,
          sintPages: [
            SintPage(
              name: AppRouteConstants.root,
              page: () => SintBuilder<SplashController>(
                init: SplashController(),
                builder: (_) => const Scaffold(body: Text('RootSplash')),
              ),
            ),
            SintPage(
              name: AppRouteConstants.home,
              page: () => const Scaffold(body: Text('HomeRoute')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(Sint.currentRoute, AppRouteConstants.root);
      expect(find.text('RootSplash'), findsOneWidget);
      expect(find.text('HomeRoute'), findsNothing);
      expect(loginService.status, AuthStatus.waiting);
    },
  );

  testWidgets(
    'standalone /splashScreen without args still navigates to /home',
    (tester) async {
      await tester.pumpWidget(
        SintMaterialApp(
          initialRoute: AppRouteConstants.splashScreen,
          sintPages: [
            SintPage(
              name: AppRouteConstants.splashScreen,
              page: () => SintBuilder<SplashController>(
                init: SplashController(),
                builder: (_) => const Scaffold(body: Text('StandaloneSplash')),
              ),
            ),
            SintPage(
              name: AppRouteConstants.home,
              page: () => const Scaffold(body: Text('HomeRoute')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(Sint.currentRoute, AppRouteConstants.home);
      expect(find.text('HomeRoute'), findsOneWidget);
    },
  );
}
