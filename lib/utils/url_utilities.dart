
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/constants/url_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';


class UrlUtilities {
  static final RegExp _schemePrefixPattern = RegExp(
    r'^([a-zA-Z][a-zA-Z0-9+.\-]*):',
  );
  static final RegExp _idnDotHomoglyphs = RegExp(r'[\u3002\uFF0E\uFF61]');
  static final RegExp _rawTraversalPattern = RegExp(
    r'(?:^|/)\.\.(?:/|$|\?|#)|%2e%2e|%2e\.|\.%2e|%(?:2f|5c|25|00|c2%[89][0-9a-f]|d8%9c|e2%80%(?:8[b-f]|a[8-e])|e2%81%a[0-9]|ef%bb%bf)',
    caseSensitive: false,
  );
  static final RegExp _invisibleOrBidiStripInScan = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028\u2029\u202A-\u202E\u2060-\u2069\uFEFF]',
  );
  static const List<String> _reservedInternalSuffixes = <String>[
    '.localhost',
    '.local',
    '.internal',
    '.corp',
    '.lan',
    '.home.arpa',
    '.invalid',
    '.onion',
    '.ts.net',
    '.metadata.google.internal',
    '.metadata.goog',
    '.metadata.azure.com',
    '.metadata.azure.internal',
  ];

  static const int _maxExtractedTextScanLength = 8192;

  static String _prepareBoundedScanText(String text) {
    final bounded = text.length > _maxExtractedTextScanLength
        ? text.substring(0, _maxExtractedTextScanLength)
        : text;
    return bounded.replaceAll(_invisibleOrBidiStripInScan, ' ');
  }

  static String getYouTubeUrl(String text) {
    if (text.isEmpty) return '';
    final bounded = _prepareBoundedScanText(text);
    RegExp regExp = RegExp(
        r'((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu\.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S{0,512})?'
    );

    String? matches = regExp.stringMatch(bounded);
    if (matches == null) return '';

    final String youTubeUrl = matches;
    return youTubeUrl;
  }

  static String getSpotifyUrl(String text) {
    if (text.isEmpty) return '';
    final bounded = _prepareBoundedScanText(text);
    RegExp regExp = RegExp(
        r'(https:\/\/open\.spotify\.com\/track\/[a-zA-Z0-9]+)|(open\.spotify\.com\/track\/[a-zA-Z0-9]+)|(spotify\.com\/track\/[a-zA-Z0-9]+)'
    );

    String? matches = regExp.stringMatch(bounded);
    if (matches == null) return '';

    final String spotifyUrl = matches;
    return spotifyUrl;
  }

  static String getUrlFromText(String text) {
    if (text.isEmpty) return '';
    final bounded = _prepareBoundedScanText(text);
    RegExp urlRegex = RegExp(r'(https?://[^\s]{1,2048})');

    String? matches = urlRegex.stringMatch(bounded);
    if (matches == null) return '';

    final String url = matches;
    return url;
  }

  static String removeQueryParameters(String url) {
    final int questionMarkIndex = url.indexOf('?');
    final int fragmentIndex = url.indexOf('#');
    int cutIndex = -1;
    if (questionMarkIndex != -1 && fragmentIndex != -1) {
      cutIndex = questionMarkIndex < fragmentIndex
          ? questionMarkIndex
          : fragmentIndex;
    } else if (questionMarkIndex != -1) {
      cutIndex = questionMarkIndex;
    } else if (fragmentIndex != -1) {
      cutIndex = fragmentIndex;
    }
    if (cutIndex == -1) {
      return url;
    }

    return url.substring(0, cutIndex);
  }

  static bool _hasControlChars(String value, {bool allowOuterAsciiSpaces = false}) {
    for (int i = 0; i < value.length; i++) {
      final unit = value.codeUnitAt(i);
      if (allowOuterAsciiSpaces && unit == 0x20) continue;
      if (unit <= 0x20 ||
          (unit >= 0x7F && unit <= 0x9F) ||
          unit == 0x061C ||
          (unit >= 0x200B && unit <= 0x200F) ||
          unit == 0x2028 ||
          unit == 0x2029 ||
          (unit >= 0x202A && unit <= 0x202E) ||
          (unit >= 0x2060 && unit <= 0x2069) ||
          unit == 0xFEFF) {
        return true;
      }
    }
    return false;
  }

  static Uri? _parseNormalizedExternalUri(String rawUrl) {
    if (_hasControlChars(rawUrl, allowOuterAsciiSpaces: true)) {
      return null;
    }
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 4096 ||
        trimmed.contains('\\') ||
        trimmed.startsWith('//') ||
        _rawTraversalPattern.hasMatch(trimmed) ||
        _idnDotHomoglyphs.hasMatch(trimmed) ||
        _hasControlChars(trimmed)) {
      return null;
    }
    String candidate = trimmed;
    final schemeMatch = _schemePrefixPattern.firstMatch(trimmed);
    if (schemeMatch != null) {
      final scheme = schemeMatch.group(1)!.toLowerCase();
      final afterColon = trimmed.substring(schemeMatch.end);
      final looksLikeHostPort = scheme.contains('.') &&
          RegExp(r'^\d{1,5}(?:/|$|\?|#)').hasMatch(afterColon);
      if (looksLikeHostPort) {
        candidate = 'https://$trimmed';
      } else if ((scheme != 'http' && scheme != 'https') ||
          !trimmed.toLowerCase().startsWith('$scheme://')) {
        return null;
      }
    } else {
      candidate = 'https://$trimmed';
    }
    final uri = Uri.tryParse(candidate);
    if (uri == null || !uri.hasScheme || uri.userInfo.isNotEmpty) {
      return null;
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return null;
    }
    return uri;
  }

  static bool isExternalDomain(String url) {
    final uri = _parseNormalizedExternalUri(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;

    for (final rawDomain in UrlConstants.externalDomains) {
      final domain = rawDomain.trim().toLowerCase();
      if (domain.isEmpty) continue;
      if (host == domain || host.endsWith('.$domain')) {
        return true;
      }
    }
    return false;
  }

  static bool isValidExternalDomain(String url) {
    final uri = _parseNormalizedExternalUri(url);
    if (uri == null) {
      AppConfig.logger.d('URL is valid: false');
      return false;
    }

    final host = uri.host.toLowerCase();
    if (host.isEmpty ||
        host == 'null' ||
        host == 'localhost' ||
        host == 'metadata' ||
        host == 'instance-data' ||
        host.startsWith('.') ||
        host.endsWith('.') ||
        host.contains('..') ||
        host.contains(':')) {
      AppConfig.logger.d('URL is valid: false');
      return false;
    }
    for (final suffix in _reservedInternalSuffixes) {
      if (host.endsWith(suffix)) {
        AppConfig.logger.d('URL is valid: false');
        return false;
      }
    }

    final labels = host.split('.');
    bool isValid = labels.length >= 2;
    if (isValid) {
      for (int i = 0; i < labels.length; i++) {
        final label = labels[i];
        if (label.isEmpty ||
            label.length > 63 ||
            label.startsWith('-') ||
            label.endsWith('-')) {
          isValid = false;
          break;
        }
        final isTld = i == labels.length - 1;
        if (isTld &&
            (label.length < 2 || !RegExp(r'^[a-z]+$').hasMatch(label))) {
          isValid = false;
          break;
        }
        if (!RegExp(r'^[a-z0-9-]+$').hasMatch(label)) {
          isValid = false;
          break;
        }
      }
    }

    if (isValid && !CoreUtilities.isSafePublicMediaUri(uri)) {
      isValid = false;
    }

    AppConfig.logger.d('URL host ($host) is valid: $isValid');
    return isValid;
  }

  /// Normalizes and validates an external public HTTP(S) URL, returning `null`
  /// for unsafe schemes, private/IMDS/loopback IPs, reserved internal TLDs,
  /// WHATWG backslashes, IDN dot homoglyphs, raw path traversal, or credentials.
  static String? normalizeValidExternalUrl(String rawUrl) =>
      normalizeSafeExternalUrl(rawUrl);

  /// Canonical public HTTP(S) URL normalizer shared by `neom_commons` and
  /// `neom_admin` (`CreateSponsorController.normalizeSafeExternalUrl`).
  static String? normalizeSafeExternalUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 2048 ||
        _rawTraversalPattern.hasMatch(trimmed)) {
      return null;
    }
    if (!isValidExternalDomain(trimmed)) return null;
    return _parseNormalizedExternalUri(trimmed)?.toString();
  }

}
