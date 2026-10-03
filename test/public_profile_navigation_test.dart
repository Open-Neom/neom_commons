import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:sint/sint.dart';

class _SignedInUser extends Fake implements UserService {
  @override
  final user = AppUser(id: 'account');
}

class _FirebaseUser extends Fake implements fba.User {}

class _LoginService extends Fake implements LoginService {
  @override
  AuthStatus getAuthStatus() => AuthStatus.loggedIn;
  @override
  fba.User get fbaUser => _FirebaseUser();
}

void main() {
  late AppInUse previousApp;
  late bool previousGuestMode;

  setUp(() {
    previousApp = AppConfig.instance.appInUse;
    previousGuestMode = AppConfig.instance.isGuestMode;
    Sint.reset();
    AppConfig.instance.appInUse = AppInUse.g;
    AppConfig.instance.isGuestMode = true;
    AuthGuard.pendingRedirectRoute = null;
    AuthGuard.pendingRedirectArgs = null;
  });

  tearDown(() {
    Sint.reset();
    AppConfig.instance.appInUse = previousApp;
    AppConfig.instance.isGuestMode = previousGuestMode;
    AuthGuard.pendingRedirectRoute = null;
    AuthGuard.pendingRedirectArgs = null;
  });

  Future<void> mount(
    WidgetTester tester, {
    String profileId = 'public-artist',
    String currentProfileId = '',
    VoidCallback? mutation,
  }) async {
    await tester.pumpWidget(
      SintMaterialApp(
        initialRoute: '/test',
        sintPages: [
          SintPage(
            name: '/test',
            page: () => Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    TextButton(
                      onPressed: () => AuthGuard.openPublicProfile(
                        context,
                        profileId: profileId,
                        currentProfileId: currentProfileId,
                      ),
                      child: const Text('Open author'),
                    ),
                    if (mutation != null)
                      TextButton(
                        onPressed: () => AuthGuard.protect(context, mutation),
                        child: const Text('Follow author'),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SintPage(
            name: AppRouteConstants.mateDetails,
            page: () => const Scaffold(body: Text('Public author page')),
          ),
          SintPage(
            name: AppRouteConstants.profile,
            page: () => const Scaffold(body: Text('Personal account page')),
          ),
          SintPage(
            name: AppRouteConstants.login,
            page: () => const Scaffold(body: Text('Login page')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signed-in Gigmeout still opens its own account profile', (
    tester,
  ) async {
    AppConfig.instance.isGuestMode = false;
    Sint.put<UserService>(_SignedInUser());
    Sint.put<LoginService>(_LoginService());
    await mount(tester, currentProfileId: 'public-artist');
    await tester.tap(find.text('Open author'));
    await tester.pumpAndSettle();
    expect(find.text('Personal account page'), findsOneWidget);
    expect(find.text('Public author page'), findsNothing);
    expect(AuthGuard.isAuthenticated, isTrue);
    expect(AppConfig.instance.isGuestMode, isFalse);
  });

  testWidgets(
    'Gigmeout guest can open a public author without becoming authenticated',
    (tester) async {
      await mount(tester);
      await tester.tap(find.text('Open author'));
      await tester.pumpAndSettle();
      expect(find.text('Public author page'), findsOneWidget);
      expect(find.text(AppTranslationConstants.accountRequired), findsNothing);
      expect(AuthGuard.isAuthenticated, isFalse);
      expect(AppConfig.instance.isGuestMode, isTrue);
      expect(AuthGuard.pendingRedirectRoute, isNull);
      expect(Sint.arguments, 'public-artist');
    },
  );

  testWidgets(
    'a stale current profile ID cannot send a guest to the personal profile',
    (tester) async {
      await mount(tester, currentProfileId: 'public-artist');
      await tester.tap(find.text('Open author'));
      await tester.pumpAndSettle();
      expect(find.text('Public author page'), findsOneWidget);
      expect(find.text('Personal account page'), findsNothing);
    },
  );

  testWidgets(
    'other apps keep their authentication requirement for profile links',
    (tester) async {
      AppConfig.instance.appInUse = AppInUse.e;
      await mount(tester);
      await tester.tap(find.text('Open author'));
      await tester.pumpAndSettle();
      expect(find.text('Public author page'), findsNothing);
      expect(
        find.text(AppTranslationConstants.accountRequired),
        findsOneWidget,
      );
      expect(
        AuthGuard.pendingRedirectRoute,
        AppRouteConstants.matePath('public-artist'),
      );
    },
  );

  testWidgets('following remains protected in a Gigmeout guest session', (
    tester,
  ) async {
    var calls = 0;
    await mount(tester, mutation: () => calls++);
    await tester.tap(find.text('Follow author'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text(AppTranslationConstants.accountRequired), findsOneWidget);
  });

  testWidgets('continuing as guest closes only the account dialog', (tester) async {
    var calls = 0;
    await mount(tester, mutation: () => calls++);
    await tester.tap(find.text('Follow author'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppTranslationConstants.continueExploring));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.text('Follow author'), findsOneWidget);
    expect(find.text(AppTranslationConstants.accountRequired), findsNothing);
    expect(Sint.isOverlaid, isFalse);
    expect(AppConfig.instance.isGuestMode, isTrue);
  });

  testWidgets('signing in closes the dialog before replacing the page', (tester) async {
    var calls = 0;
    await mount(tester, mutation: () => calls++);
    await tester.tap(find.text('Follow author'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppTranslationConstants.loginSignup));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.text('Login page'), findsOneWidget);
    expect(find.text(AppTranslationConstants.accountRequired), findsNothing);
    expect(Sint.isOverlaid, isFalse);
    expect(AppConfig.instance.isGuestMode, isFalse);
    expect(AuthGuard.isAuthenticated, isFalse);
  });

  testWidgets('empty and route-shaped profile IDs cannot navigate', (
    tester,
  ) async {
    for (final id in [
      '',
      '../profile/edit',
      'artist?next=private',
      'artist#private',
      ' artist',
    ]) {
      await mount(tester, profileId: id);
      await tester.tap(find.text('Open author'));
      await tester.pumpAndSettle();
      expect(find.text('Public author page'), findsNothing);
      expect(find.text(AppTranslationConstants.accountRequired), findsNothing);
    }
  });
}
