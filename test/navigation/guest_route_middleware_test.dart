import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/navigation/guest_route_middleware.dart';
import 'package:neom_commons/navigation/guest_route_policy.dart';
import 'package:neom_commons/navigation/protected_route_auth_bootstrap.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/auth_status.dart';

void main() {
  tearDown(() {
    AuthGuard.pendingRedirectRoute = null;
    AuthGuard.pendingRedirectArgs = null;
  });

  group('NeomGuestRoutePolicy', () {
    test('enforces fail-closed allow-list with templates, prefixes, overrides, and vanity URLs', () {
      const policy = NeomGuestRoutePolicy(
        publicExactPaths: {'/', '/login'},
        publicTemplates: {'/blog/:entryId'},
        privateDynamicPathOverrides: {'/blog/editor'},
        publicPrefixes: {'/games'},
        onboardingExactPaths: {'/intro/profile'},
        allowProfileVanityUrls: true,
      );

      expect(policy.isPublic('/'), isTrue);
      expect(policy.isPublic('/blog/my-post'), isTrue);
      expect(policy.isPublic('/blog/editor'), isFalse);
      expect(policy.requiresAuthentication('/blog/editor'), isTrue);
      expect(policy.isPublic('/games/chess'), isTrue);
      expect(policy.isPublic('/@emmanuel'), isTrue);
      expect(policy.isPublic('/@emmanuel/settings'), isFalse);
      expect(policy.isOnboardingRoute('/intro/profile'), isTrue);
      expect(policy.requiresAuthentication('/intro/profile'), isTrue);
    });

    test('supports case-insensitive scoped namespace policies', () {
      const audioPolicy = NeomGuestRoutePolicy(
        scopePrefixes: {'/audioplayer'},
        publicExactPaths: {'/audioplayer', '/audioplayer/media'},
        caseInsensitive: true,
      );

      expect(audioPolicy.isInScope('/audioPlayer/downloads'), isTrue);
      expect(audioPolicy.requiresAuthentication('/audioPlayer/downloads'), isTrue);
      expect(audioPolicy.requiresAuthentication('/audioPlayer/media'), isFalse);
      expect(audioPolicy.isInScope('/event/123'), isFalse);
      expect(audioPolicy.requiresAuthentication('/event/123'), isFalse);
    });
  });

  group('NeomGuestRouteMiddleware', () {
    test('redirects unauthenticated guests and preserves target route and args', () {
      const policy = NeomGuestRoutePolicy(publicExactPaths: {'/'});
      final args = {'id': '42'};
      final middleware = NeomGuestRouteMiddleware(
        policy: policy,
        isAuthenticated: () => false,
        currentArguments: () => args,
      );

      final redirect = middleware.redirect('/shop/checkout?ref=test');
      expect(redirect?.name, AppRouteConstants.login);
      expect(AuthGuard.pendingRedirectRoute, '/shop/checkout?ref=test');
      expect(AuthGuard.pendingRedirectArgs, same(args));
    });

    test('allows onboarding routes when onboarding authentication succeeds', () {
      const policy = NeomGuestRoutePolicy(
        publicExactPaths: {'/'},
        onboardingExactPaths: {'/intro/profile'},
      );
      final middleware = NeomGuestRouteMiddleware(
        policy: policy,
        isAuthenticated: () => false,
        isOnboardingAuthenticated: () => true,
      );

      expect(middleware.redirect('/intro/profile'), isNull);
      expect(middleware.redirect('/shop/checkout')?.name, AppRouteConstants.login);
    });
  });

  group('ProtectedRouteAuthBootstrap', () {
    test('returns immediately once authenticated or definitively unauthenticated', () async {
      final authRes = await ProtectedRouteAuthBootstrap.waitForResolution(
        isAuthenticated: () => true,
        readAuthStatus: () => AuthStatus.waiting,
      );
      expect(authRes, ProtectedRouteAuthResolution.authenticated);

      final unauthRes = await ProtectedRouteAuthBootstrap.waitForResolution(
        isAuthenticated: () => false,
        readAuthStatus: () => AuthStatus.notLoggedIn,
      );
      expect(unauthRes, ProtectedRouteAuthResolution.unauthenticated);
    });
  });
}
