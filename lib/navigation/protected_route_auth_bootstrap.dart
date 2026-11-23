import 'package:neom_core/utils/enums/auth_status.dart';

typedef AuthStatusReader = AuthStatus? Function();
typedef AuthenticationReader = bool Function();
typedef BootstrapDelay = Future<void> Function(Duration duration);

/// Outcome of waiting for the initial authentication decision before a
/// protected route crosses a host app's navigation middleware.
enum ProtectedRouteAuthResolution { authenticated, unauthenticated, timedOut }

/// Keeps a protected page out of the route stack while Firebase Auth and the
/// user profile finish restoring after a browser refresh.
///
/// This is deliberately only a bootstrap wait. It never authorizes a route:
/// after it resolves, [NeomGuestRouteMiddleware] evaluates the normal strict
/// [AuthGuard] again. An unauthenticated result or timeout therefore remains
/// fail-closed and is redirected to login.
class ProtectedRouteAuthBootstrap {
  ProtectedRouteAuthBootstrap._();

  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration defaultPollInterval = Duration(milliseconds: 50);

  static Future<ProtectedRouteAuthResolution> waitForResolution({
    required AuthenticationReader isAuthenticated,
    required AuthStatusReader readAuthStatus,
    Duration timeout = defaultTimeout,
    Duration pollInterval = defaultPollInterval,
    BootstrapDelay delay = Future<void>.delayed,
  }) async {
    final stopwatch = Stopwatch()..start();

    while (true) {
      // The strict activity gate includes Firebase user, app auth status,
      // hydrated profile, and guest-mode state. It is the only success path.
      if (isAuthenticated()) {
        return ProtectedRouteAuthResolution.authenticated;
      }

      final status = readAuthStatus();
      if (status == AuthStatus.notLoggedIn) {
        return ProtectedRouteAuthResolution.unauthenticated;
      }

      // `loggedIn` with a false strict gate is still pending profile hydration
      // (or an inconsistent session). Never expose the protected page in that
      // window; timeout falls through to the middleware's login redirect.
      if (stopwatch.elapsed >= timeout) {
        return ProtectedRouteAuthResolution.timedOut;
      }

      final remaining = timeout - stopwatch.elapsed;
      await delay(remaining < pollInterval ? remaining : pollInterval);
    }
  }
}
