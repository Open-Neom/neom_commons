import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/user_role.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:sint/sint.dart';
import 'package:url_launcher/url_launcher.dart';

/// Brand-isolated cross-subdomain SSO launcher from any consumer platform
/// (`emxi.org`, `gigmeout.com`, `cyberneom.xyz`, `itzli.mx`, `blup.mx`,
/// `vrlizate.com`, `letrograf.com`) to its corresponding **Admineom** console
/// (`admin.<brand>`).
///
/// Security & UX invariants:
/// - **Role-gated**: callers should hide admin UI entries unless
///   [canAccess] returns `true` for the destination's minimum [UserRole], and
///   [open] double-checks the role before issuing any network request.
/// - **Single-brand isolation**: calls the active Firebase project's own
///   `issueSsoHandoffCode` Cloud Function authenticated with the staff
///   member's Firebase ID token, validating that the returned `targetUrl`
///   stays strictly on `https://<expectedAdminDomain>`.
/// - **Inside Admineom**: when [AppConfig.isAdminConsoleHost] is `true`,
///   [open] navigates locally with `Sint.toNamed` instead of re-launching a
///   browser tab.
class AdmineomSsoLauncher {
  AdmineomSsoLauncher._();

  static const Duration _handoffTimeout = Duration(seconds: 6);
  static final RegExp _safePathRe = RegExp(r'^\/[a-zA-Z0-9/_-]{1,160}$');

  /// Canonical `admin.<brand>` host for each Open Neom app.
  static String adminDomainFor(AppInUse app) {
    switch (app) {
      case AppInUse.e:
        return 'admin.emxi.org';
      case AppInUse.g:
        return 'admin.gigmeout.com';
      case AppInUse.c:
        return 'admin.cyberneom.xyz';
      case AppInUse.i:
        return 'admin.itzli.mx';
      case AppInUse.b:
        return 'admin.blup.mx';
      case AppInUse.v:
        return 'admin.vrlizate.com';
      case AppInUse.l:
        return 'admin.letrograf.com';
      case AppInUse.a:
      case AppInUse.o:
      default:
        return 'admin.openneom.dev';
    }
  }

  /// Canonical `https://admin.<brand>` origin for [app].
  static String adminOriginFor(AppInUse app) => 'https://${adminDomainFor(app)}';

  /// Sanitizes an optional deep route inside Admineom (e.g. `/founding/admin`).
  /// Returns `''` when root or invalid so untrusted input can never alter the
  /// target host or inject query/fragment components.
  static String sanitizeTargetPath(String? rawPath) {
    final trimmed = (rawPath ?? '').trim();
    if (trimmed.isEmpty || trimmed == '/') return '';
    if (trimmed.contains('..') || trimmed.contains('//')) return '';
    if (!_safePathRe.hasMatch(trimmed)) return '';
    return trimmed;
  }

  /// Builds the direct HTTPS fallback URL for [app] and optional [targetPath].
  static Uri buildFallbackUri(AppInUse app, {String targetPath = ''}) {
    final cleanPath = sanitizeTargetPath(targetPath);
    return Uri.parse('${adminOriginFor(app)}$cleanPath');
  }

  /// Resolves the signed-in user's [UserRole], or [UserRole.subscriber] when
  /// browsing as guest / unauthenticated.
  static UserRole currentUserRole() {
    if (AppConfig.instance.isGuestMode) return UserRole.subscriber;
    if (!Sint.isRegistered<UserService>()) return UserRole.subscriber;
    try {
      final user = Sint.find<UserService>().user;
      if (user.id.isEmpty) return UserRole.subscriber;
      return user.userRole;
    } catch (_) {
      return UserRole.subscriber;
    }
  }

  /// Pure role policy check — true only when the signed-in user has at least
  /// [minimumRole] (never true for guests or subscribers).
  static bool hasRequiredRole(
    UserRole actual, {
    UserRole minimumRole = UserRole.support,
  }) {
    final floor = minimumRole.value < UserRole.support.value
        ? UserRole.support.value
        : minimumRole.value;
    return actual.value >= floor;
  }

  /// Returns `true` iff the current session is authenticated staff with at
  /// least [minimumRole]. Use this to guard visibility of EVERY button/link
  /// targeting Admineom.
  static bool canAccess({UserRole minimumRole = UserRole.support}) {
    if (AppConfig.instance.isGuestMode) return false;
    return hasRequiredRole(currentUserRole(), minimumRole: minimumRole);
  }

  /// Opens Admineom at [targetPath] (defaulting to the Admineom dashboard)
  /// with a single-use SSO handoff code scoped strictly to the active brand's
  /// Firebase project.
  ///
  /// When already running inside Admineom ([AppConfig.isAdminConsoleHost]),
  /// navigates locally via `Sint.toNamed` instead of launching an external URL.
  static Future<bool> open({
    String targetPath = '',
    UserRole minimumRole = UserRole.support,
    AppInUse? appOverride,
    String? projectIdOverride,
    fba.FirebaseAuth? firebaseAuth,
    http.Client? httpClient,
    Future<bool> Function(Uri uri)? launcher,
  }) async {
    if (!canAccess(minimumRole: minimumRole)) {
      return false;
    }

    final cleanPath = sanitizeTargetPath(targetPath);

    if (AppConfig.instance.isAdminConsoleHost) {
      final localRoute = cleanPath.isEmpty ? AppRouteConstants.home : cleanPath;
      Sint.toNamed(localRoute);
      return true;
    }

    final app = appOverride ?? AppConfig.instance.appInUse;
    final expectedHost = adminDomainFor(app).toLowerCase();
    final adminOrigin = adminOriginFor(app);
    final fallbackUri = buildFallbackUri(app, targetPath: cleanPath);
    final launchFn = launcher ?? _launchUri;

    final fba.FirebaseAuth? auth = _resolveAuth(firebaseAuth);
    final user = auth?.currentUser;
    if (user == null || user.isAnonymous) {
      return launchFn(fallbackUri);
    }

    final projectId = _resolveProjectId(projectIdOverride);
    if (projectId.isEmpty) {
      return launchFn(fallbackUri);
    }

    final client = httpClient ?? http.Client();
    try {
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        return await launchFn(fallbackUri);
      }

      final endpoint = Uri.parse(
        'https://us-central1-$projectId.cloudfunctions.net/issueSsoHandoffCode',
      );
      final payload = <String, dynamic>{
        'targetOrigin': adminOrigin,
        if (cleanPath.isNotEmpty) 'targetPath': cleanPath,
      };
      final response = await client
          .post(
            endpoint,
            headers: <String, String>{
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_handoffTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final targetUrl = (decoded['targetUrl'] ?? '').toString().trim();
          final parsed = parseVerifiedTargetUrl(
            targetUrl,
            expectedHost: expectedHost,
          );
          if (parsed != null) {
            return await launchFn(parsed);
          }
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_commons',
        operation: 'AdmineomSsoLauncher.open',
      );
    } finally {
      if (httpClient == null) client.close();
    }

    return launchFn(fallbackUri);
  }

  /// Validates that [rawTargetUrl] is a strict HTTPS URL matching [expectedHost].
  @visibleForTesting
  static Uri? parseVerifiedTargetUrl(
    String rawTargetUrl, {
    required String expectedHost,
  }) {
    final parsed = Uri.tryParse(rawTargetUrl.trim());
    if (parsed == null) return null;
    if (parsed.scheme.toLowerCase() != 'https') return null;
    if (parsed.host.toLowerCase() != expectedHost.toLowerCase()) return null;
    if (parsed.userInfo.isNotEmpty) return null;
    return parsed;
  }

  static fba.FirebaseAuth? _resolveAuth(fba.FirebaseAuth? injected) {
    if (injected != null) return injected;
    try {
      return fba.FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static String _resolveProjectId(String? override) {
    final trimmed = (override ?? '').trim();
    if (trimmed.isNotEmpty) return trimmed;
    try {
      return Firebase.app().options.projectId.trim();
    } catch (_) {
      return '';
    }
  }

  static Future<bool> _launchUri(Uri uri) async {
    if (kIsWeb) {
      final openedTab = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (openedTab) return true;
      // Fallback if a strict browser popup blocker cancelled `_blank` after
      // the async SSO token exchange.
      return launchUrl(uri, webOnlyWindowName: '_self');
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
