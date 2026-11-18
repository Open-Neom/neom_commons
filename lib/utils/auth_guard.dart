import 'package:flutter/material.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/public_catalog_read_policy.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import '../ui/theme/app_color.dart';
import 'constants/translations/app_translation_constants.dart';

class AuthGuard {
  static String? pendingRedirectRoute;
  static dynamic pendingRedirectArgs;

  static const int maxRedirectRouteLength = 512;
  static const int maxProfileIdLength = 128;

  static final RegExp _unsafeControlOrBidi = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u061C\u200B-\u200F\u2028\u2029\u202A-\u202E\u2060-\u2069\uFEFF]',
  );
  static final RegExp _encodedTraversalOrNull = RegExp(
    r'(?:^|/)\.\.(?:/|$|\?|#)|%2e%2e|%2e\.|\.%2e|%2f|%5c|%25|%00',
    caseSensitive: false,
  );
  static const Set<String> _forbiddenProfileIds = <String>{
    '.',
    '..',
    '__proto__',
    'constructor',
    'prototype',
  };

  /// Validates that [profileId] is a safe Firestore/route identifier free of
  /// traversal segments, prototype-pollution keys, separators, or BiDi/controls.
  static bool isSafeProfileId(String profileId) {
    if (profileId.isEmpty ||
        profileId.length > maxProfileIdLength ||
        profileId != profileId.trim() ||
        _unsafeControlOrBidi.hasMatch(profileId) ||
        profileId.contains(RegExp(r'[/\\?#\s]')) ||
        profileId.contains('..')) {
      return false;
    }
    final lower = profileId.toLowerCase();
    if (_forbiddenProfileIds.contains(lower) ||
        (profileId.startsWith('__') && profileId.endsWith('__')) ||
        lower.contains('%00') ||
        lower.contains('%2e') ||
        lower.contains('%2f') ||
        lower.contains('%5c') ||
        lower.contains('%25')) {
      return false;
    }
    return true;
  }

  /// Validates an internal post-login redirect route so external schemes,
  /// protocol-relative `//host`, dot-segment escapes, and auth-loop routes
  /// are rejected before storing in [pendingRedirectRoute].
  static String? sanitizeRedirectRoute(Object? candidate) {
    if (candidate is! String || _unsafeControlOrBidi.hasMatch(candidate)) {
      return null;
    }
    final trimmed = candidate.trim();
    if (trimmed.isEmpty ||
        trimmed.length > maxRedirectRouteLength ||
        !trimmed.startsWith('/') ||
        trimmed.startsWith('//') ||
        trimmed.contains(r'\') ||
        trimmed.contains('://') ||
        _unsafeControlOrBidi.hasMatch(trimmed) ||
        _encodedTraversalOrNull.hasMatch(trimmed)) {
      return null;
    }
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || parsed.hasScheme || parsed.hasAuthority) {
      return null;
    }
    var normalizedPath = parsed.path;
    while (normalizedPath.length > 1 && normalizedPath.endsWith('/')) {
      normalizedPath = normalizedPath.substring(0, normalizedPath.length - 1);
    }
    if (normalizedPath == AppRouteConstants.login ||
        normalizedPath == AppRouteConstants.signup ||
        normalizedPath == AppRouteConstants.forgotPassword ||
        normalizedPath == AppRouteConstants.logout) {
      return null;
    }
    return trimmed;
  }

  /// Opening an author's public profile is a catalogue read in Gigmeout.
  /// The destination revalidates it through publicProfiles; account actions
  /// still go through [protect], including in that public profile page.
  static void openPublicProfile(
    BuildContext context, {
    required String profileId,
    String currentProfileId = '',
    bool closeOverlay = false,
  }) {
    if (!isSafeProfileId(profileId)) {
      return;
    }

    final publicCatalog = PublicCatalogReadPolicy.enabled;
    final route = isAuthenticated && profileId == currentProfileId
        ? AppRouteConstants.profile
        : AppRouteConstants.matePath(profileId);
    void open() {
      if (closeOverlay) Sint.pop();
      Sint.toNamed(route, arguments: profileId);
    }

    if (publicCatalog) {
      open();
    } else {
      protect(context, open, redirectRoute: route, arguments: profileId);
    }
  }

  /// ÚNICO punto de acceso.
  ///
  /// [action]: La función que se ejecuta SI el usuario está autenticado.
  /// [redirectRoute]: (Opcional) Si es Guest, a dónde lo enviamos después de que se registre exitosamente.
  /// [arguments]: (Opcional) Argumentos para esa ruta de redirección.
  static void protect(
    BuildContext context,
    VoidCallback action, {
    String? redirectRoute,
    dynamic arguments,
  }) {
    if (_userIsLoggedIn()) {
      // 1. Usuario Real: Pasa directo a la acción.
      action();
    } else {
      final safeRedirect = sanitizeRedirectRoute(redirectRoute);
      // Guard redirect route for global session persistence (across onboarding steps)
      pendingRedirectRoute = safeRedirect;
      pendingRedirectArgs = safeRedirect != null ? arguments : null;

      // 2. Usuario Guest: Se interrumpe la acción y se muestra el modal.
      showGuestModal(
        context,
        redirectRoute: safeRedirect,
        arguments: safeRedirect != null ? arguments : null,
      );
    }
  }

  /// Verifica si el usuario está autenticado realmente.
  /// Public para que controllers puedan hacer guards silenciosos (sin UI).
  static bool get isAuthenticated => _userIsLoggedIn();

  /// Uses the same strict gate as persistence controllers: leaving guest mode
  /// is not authentication, and a stale local user after Firebase logout must
  /// not unlock protected routes or actions.
  static bool _userIsLoggedIn() => AppConfig.instance.canPersistUserActivity;

  /// Muestra el diálogo y configura la redirección (Privado)
  static void showGuestModal(
    BuildContext context, {
    String? redirectRoute,
    dynamic arguments,
  }) {
    final safeRedirect = sanitizeRedirectRoute(redirectRoute);
    final safeArguments = safeRedirect != null ? arguments : null;
    Sint.dialog(
      AlertDialog(
        backgroundColor: AppColor.scaffold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          AppTranslationConstants.accountRequired.tr,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppTranslationConstants.guestActionPrompt.tr,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Sint.closeDialog(),
            child: Text(
              AppTranslationConstants.continueExploring.tr,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.getReleaseShelfColor(),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              Sint.closeDialog();

              // 2. Apagar modo invitado (para que RootPage sepa que vamos al Login real)
              AppConfig.instance.isGuestMode = false;

              // 3. Ir al Login llevando la "Promesa" de redirección
              Sint.offAllNamed(
                AppRouteConstants.login,
                arguments: {'nextRoute': safeRedirect, 'nextArgs': safeArguments},
              );
            },
            child: Text(AppTranslationConstants.loginSignup.tr),
          ),
        ],
      ),
      barrierDismissible: true, // Permite cerrar tocando fuera
    );
  }
}
