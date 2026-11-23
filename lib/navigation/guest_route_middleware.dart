import 'dart:async';

import 'package:flutter/material.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:sint/sint.dart';

import '../utils/auth_guard.dart';
import 'guest_route_policy.dart';
import 'protected_route_auth_bootstrap.dart';

typedef RouteArgumentsReader = Object? Function();
typedef AuthenticationResolutionWaiter = Future<void> Function(String? route);

/// Shared guest-only navigation middleware for Open Neom host apps.
///
/// Evaluates a [NeomGuestRoutePolicy], optionally waits for initial Firebase
/// auth restoration on hard browser reloads ([waitForAuthBootstrap]), and
/// redirects unauthenticated guests to [AppRouteConstants.login] while
/// preserving the original target route, query parameters, and arguments.
class NeomGuestRouteMiddleware extends SintMiddleware {
  NeomGuestRouteMiddleware({
    required this.policy,
    AuthenticationReader? isAuthenticated,
    AuthenticationReader? isOnboardingAuthenticated,
    RouteArgumentsReader? currentArguments,
    AuthenticationResolutionWaiter? waitForAuthenticationResolution,
    this.waitForAuthBootstrap = true,
    super.priority = -1000,
  }) : _isAuthenticated = isAuthenticated ?? readAuthentication,
       _isOnboardingAuthenticated =
           isOnboardingAuthenticated ?? readOnboardingAuthentication,
       _currentArguments = currentArguments ?? readCurrentArguments,
       _customWaitForAuthenticationResolution = waitForAuthenticationResolution;

  final NeomGuestRoutePolicy policy;
  final bool waitForAuthBootstrap;
  final AuthenticationReader _isAuthenticated;
  final AuthenticationReader _isOnboardingAuthenticated;
  final RouteArgumentsReader _currentArguments;
  final AuthenticationResolutionWaiter? _customWaitForAuthenticationResolution;

  @override
  RouteSettings? redirect(String? route) {
    if (!_mustRedirect(route)) return null;

    final arguments = _currentArguments();
    _rememberTarget(route, arguments);
    return RouteSettings(
      name: AppRouteConstants.login,
      arguments: _loginArguments(route, arguments),
    );
  }

  @override
  FutureOr<RouteDecoder?> redirectDelegate(RouteDecoder route) async {
    final requestedRoute = route.pageSettings?.name ?? route.route?.name;

    if (waitForAuthBootstrap &&
        policy.requiresAuthentication(requestedRoute) &&
        !_isAuthorizedForRoute(requestedRoute)) {
      final waiter = _customWaitForAuthenticationResolution;
      if (waiter != null) {
        await waiter(requestedRoute);
      } else {
        await _waitForInitialAuthentication(
          requestedRoute,
          () => _isAuthorizedForRoute(requestedRoute),
        );
      }
    }

    if (!_mustRedirect(requestedRoute)) return route;

    final arguments = route.pageSettings?.arguments;
    _rememberTarget(requestedRoute, arguments);
    return RouteDecoder.fromRoute(AppRouteConstants.login);
  }

  bool _mustRedirect(String? route) =>
      policy.requiresAuthentication(route) && !_isAuthorizedForRoute(route);

  bool _isAuthorizedForRoute(String? route) {
    if (_isAuthenticated()) return true;
    if (policy.isOnboardingRoute(route) && _isOnboardingAuthenticated()) {
      return true;
    }
    return false;
  }

  static bool readAuthentication() => AuthGuard.isAuthenticated;

  /// Allows onboarding routes (`/intro/*`) when Firebase Auth has a
  /// non-anonymous user and `LoginController` confirmed Firestore has no
  /// existing account yet (`isNewUser` with bound `user.id == fbaUser.uid`).
  static bool readOnboardingAuthentication() {
    if (!Sint.isRegistered<LoginService>() ||
        !Sint.isRegistered<UserService>()) {
      return false;
    }

    try {
      final login = Sint.find<LoginService>();
      final fbaUser = login.fbaUser ?? login.auth.currentUser;
      if (fbaUser == null || fbaUser.isAnonymous) return false;
      if (login.getAuthStatus() != AuthStatus.loggedIn) return false;

      final userService = Sint.find<UserService>();
      return userService.isNewUser &&
          userService.user.id.isNotEmpty &&
          userService.user.id == fbaUser.uid;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _waitForInitialAuthentication(
    String? route,
    AuthenticationReader isAuthorized,
  ) async {
    final resolution = await ProtectedRouteAuthBootstrap.waitForResolution(
      isAuthenticated: isAuthorized,
      readAuthStatus: _readAuthStatus,
    );

    if (resolution == ProtectedRouteAuthResolution.timedOut) {
      AppConfig.logger.w(
        'Authentication bootstrap timed out for $route; redirecting to login.',
      );
    }
  }

  static AuthStatus? _readAuthStatus() {
    if (!Sint.isRegistered<LoginService>()) return null;

    try {
      return Sint.find<LoginService>().getAuthStatus();
    } catch (_) {
      return null;
    }
  }

  static Object? readCurrentArguments() {
    try {
      return Sint.arguments;
    } catch (_) {
      return null;
    }
  }

  void _rememberTarget(String? route, Object? arguments) {
    if (policy.isOnboardingRoute(route)) return;
    AuthGuard.pendingRedirectRoute = route;
    AuthGuard.pendingRedirectArgs = arguments;
  }

  Map<String, Object?> _loginArguments(String? route, Object? arguments) =>
      policy.isOnboardingRoute(route)
          ? const <String, Object?>{}
          : {'nextRoute': route, 'nextArgs': arguments};
}
