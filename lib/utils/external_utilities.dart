import 'package:flutter/foundation.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/place.dart';
import 'package:neom_core/utils/constants/url_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'url_utilities.dart';

class ExternalUtilities {
  static final RegExp _forbiddenLaunchChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u061C\u200B-\u200F\u2028\u2029\u202A-\u202E\u2060-\u2069\uFEFF]',
  );
  static final RegExp _encodedCrlfOrNull = RegExp(
    r'%0[0ad]',
    caseSensitive: false,
  );
  static final RegExp _whatsappInternalPromptRe = RegExp(
    r'<\|(?:channel|turn)\s*>\s*thought\b[\s\S]*?(?:<(?:channel|turn)\|>|$)'
    r'|<\|tool_call\s*>[\s\S]*?(?:<tool_call\|>|$)'
    r'|<(?:think|thought|memory_recall|auto_memory|system_context)\b[^>]*>[\s\S]*?(?:</(?:think|thought|memory_recall|auto_memory|system_context)>|$)'
    r'|<(?:channel|turn|tool_call)\|>|<\|/?(?:turn|channel|tool_call|im_start|im_end|eot_id)\|>',
    caseSensitive: false,
  );
  static final RegExp _idnDotHomoglyphs = RegExp(r'[\u3002\uFF0E\uFF61]');
  static final RegExp _schemePrefixPattern = RegExp(
    r'^([a-zA-Z][a-zA-Z0-9+.\-]*):',
  );
  static final RegExp _safeTelPattern = RegExp(r'^\+?[0-9()\-.\s]{3,24}$');

  static bool get _supportsEmbeddedMobileWebView =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) &&
      WebViewPlatform.instance != null;

  /// Normalizes and validates an external launch URL, blocking dangerous
  /// schemes (`javascript:`, `data:`, `vbscript:`, `file:`, `blob:`),
  /// credential-bearing URLs, backslashes, control/BiDi characters, and
  /// private/loopback/IMDS HTTP(S) targets.
  static Uri? normalizeSafeLaunchUri(String rawUrl) {
    if (_forbiddenLaunchChars.hasMatch(rawUrl)) {
      return null;
    }
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 4096 ||
        trimmed.contains('\\') ||
        _idnDotHomoglyphs.hasMatch(trimmed) ||
        _forbiddenLaunchChars.hasMatch(trimmed)) {
      return null;
    }

    final schemeMatch = _schemePrefixPattern.firstMatch(trimmed);
    String candidate = trimmed;
    if (schemeMatch != null) {
      final scheme = schemeMatch.group(1)!.toLowerCase();
      // Distinguish `host:port` (e.g. `example.com:8443/path`) from schemes:
      final afterColon = trimmed.substring(schemeMatch.end);
      final looksLikeHostPort = scheme.contains('.') &&
          RegExp(r'^\d{1,5}(?:/|$)').hasMatch(afterColon);
      if (looksLikeHostPort) {
        candidate = 'https://$trimmed';
      } else if (scheme != 'http' &&
          scheme != 'https' &&
          scheme != 'mailto' &&
          scheme != 'tel') {
        return null;
      }
    } else if (trimmed.startsWith('//')) {
      return null;
    } else {
      candidate = 'https://$trimmed';
    }

    final uri = Uri.tryParse(candidate);
    if (uri == null || !uri.hasScheme) return null;
    final lowerScheme = uri.scheme.toLowerCase();
    if (lowerScheme == 'http' || lowerScheme == 'https') {
      if (!CoreUtilities.isSafePublicMediaUri(uri)) return null;
      return uri;
    }
    if (lowerScheme == 'mailto') {
      if (uri.path.trim().isEmpty ||
          uri.path.contains(' ') ||
          _encodedCrlfOrNull.hasMatch(trimmed)) {
        return null;
      }
      return uri;
    }
    if (lowerScheme == 'tel') {
      if (!_safeTelPattern.hasMatch(uri.path.trim()) ||
          _encodedCrlfOrNull.hasMatch(trimmed)) {
        return null;
      }
      return uri;
    }
    return null;
  }

  /// Builds a validated `https://` WhatsApp deep-link URI with digits-only
  /// E.164 phone number and URL-encoded message text.
  static Uri? buildSafeWhatsappUri({
    required String templateUrl,
    required String phone,
    required String message,
  }) {
    final cleanDigits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanDigits.length < 7 || cleanDigits.length > 15) return null;
    final cleanMsg = message
        .replaceAll(_whatsappInternalPromptRe, '')
        .replaceAll(
          RegExp(
            r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F\u061C\u200B-\u200F\u2028\u2029\u202A-\u202E\u2060-\u2069\uFEFF]',
          ),
          '',
        );
    final encodedMsg = Uri.encodeComponent(cleanMsg);

    if (_forbiddenLaunchChars.hasMatch(templateUrl)) return null;
    var raw = templateUrl.trim();
    if (raw.isEmpty ||
        raw.contains('\\') ||
        _idnDotHomoglyphs.hasMatch(raw) ||
        _forbiddenLaunchChars.hasMatch(raw)) {
      return null;
    }
    raw = raw.replaceAll('<phoneNumber>', cleanDigits);
    raw = raw.replaceAll('<message>', encodedMsg);
    if (!raw.startsWith('https://') && !raw.startsWith('http://')) {
      raw = 'https://$raw';
    } else if (raw.startsWith('http://')) {
      raw = 'https://${raw.substring(7)}';
    }
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    final host = uri.host.toLowerCase();
    if (host != 'wa.me' &&
        host != 'api.whatsapp.com' &&
        host != 'web.whatsapp.com' &&
        !host.endsWith('.whatsapp.com')) {
      return null;
    }
    return uri;
  }

  static void launchURL(String url, {bool openInApp = true, bool clearCache = false, bool clearCookies = false, bool sameTab = false}) async {
    final safeUri = normalizeSafeLaunchUri(url);
    if (safeUri == null) {
      AppConfig.logger.w('Blocked unsafe external launch URL');
      return;
    }
    final normalizedUrl = safeUri.toString();

    AppConfig.logger.d('Launching: $normalizedUrl - openInApp: $openInApp');

    try {
      if (await canLaunchUrl(safeUri)) {

        if(openInApp && UrlUtilities.isExternalDomain(normalizedUrl)) {
          openInApp = false;
        }

        if (kIsWeb) {
          // Web: open in new tab (default) or same tab
          await launchUrl(safeUri,
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: sameTab ? '_self' : '_blank',
          );
        } else if (!_supportsEmbeddedMobileWebView) {
          // Desktop (macOS / Windows / Linux): `webview_flutter` & `inAppWebView`
          // are mobile-only; open externally to prevent `UnimplementedError`.
          await launchUrl(
            safeUri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          if(clearCache) await clearWebViewCache();
          if(clearCookies) await clearWebViewCookies();

          await launchUrl(safeUri,
            mode: openInApp ? LaunchMode.inAppWebView : LaunchMode.externalApplication,
          );
        }

      } else {
        AppConfig.logger.i('Could not launch $normalizedUrl');
      }
    } catch(e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'launchURL');
    }
  }

  static void launchWhatsappURL(String phone, String message) async {
    AppConfig.logger.d('Launching Whatsapp');

    try {
      final safeUri = buildSafeWhatsappUri(
        templateUrl: AppProperties.getWhatsappUrl(),
        phone: phone,
        message: message,
      );
      if (safeUri == null) {
        AppConfig.logger.w('Blocked invalid WhatsApp phone or template URL');
        return;
      }

      if (await canLaunchUrl(safeUri)) {
        await launchUrl(safeUri, mode: LaunchMode.externalApplication);
      } else {
        AppConfig.logger.i('Could not launch WhatsApp URL');
      }
    } catch(e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'launchWhatsappURL');
    }
  }

  static void launchGoogleMaps({String? address, Place? place}) async {
    try {
      String mapsQuery = '';
      if(address != null && address.trim().isNotEmpty) {
        mapsQuery = address.trim();
      } else if(place != null) {
        final parts = <String>[
          place.name.trim(),
          if (place.address != null) ...[
            place.address!.street.trim(),
            place.address!.city.trim(),
            place.address!.state.trim(),
            place.address!.country.trim(),
          ],
        ].where((p) => p.isNotEmpty).toList(growable: false);
        mapsQuery = parts.join(', ');
        AppConfig.logger.i(mapsQuery);
      }
      if (mapsQuery.isEmpty) return;

      String mapOptions = Uri.encodeComponent(mapsQuery);
      final String googleMapsUrl = '${UrlConstants.googleMapsURL}$mapOptions';
      launchURL(googleMapsUrl);
    } catch(e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_commons', operation: 'launchGoogleMaps');
    }
  }

  static Future<void> clearWebViewCache() async {
    if (!_supportsEmbeddedMobileWebView) return;
    WebViewController webViewController = WebViewController();
    await webViewController.clearCache();
  }

  static Future<void> clearWebViewCookies() async {
    if (!_supportsEmbeddedMobileWebView) return;
    WebViewCookieManager cookieManager = WebViewCookieManager();
    await cookieManager.clearCookies();
  }

}
