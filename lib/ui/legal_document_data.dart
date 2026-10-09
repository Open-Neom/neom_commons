import 'dart:convert';

/// Public values only: source JSON and arbitrary configuration are never shown.
class LegalDocumentData {
  final String appName;
  final String controllerName;
  final String contactEmail;
  final String updatedAt;
  final int themeColor;
  final Uri origin;

  const LegalDocumentData._({
    required this.appName,
    required this.controllerName,
    required this.contactEmail,
    required this.updatedAt,
    required this.themeColor,
    required this.origin,
  });

  factory LegalDocumentData.fromSources({
    String? metadataJson,
    required String privacyPolicyUrl,
    String fallbackAppName = '',
    String fallbackContactEmail = '',
    String fallbackSiteUrl = '',
  }) {
    final privacy = _canonicalHttps(privacyPolicyUrl);
    final validPrivacy =
        privacy != null &&
        (privacy.path == '/politica-de-privacidad/' ||
            privacy.path == '/politica-de-privacidad');
    // Match the web generator: an optional invalid canonical falls back to the
    // configured site, which must independently pass the same HTTPS checks.
    final site = validPrivacy ? privacy : _canonicalHttps(fallbackSiteUrl);
    if (site == null) throw const FormatException('Missing legal site URL');
    String name;
    String controller;
    String email;
    String date;
    var color = 0xff111c41;
    if (metadataJson == null) {
      name = fallbackAppName.trim();
      controller = name;
      email = fallbackContactEmail.trim();
      date = '';
    } else {
      final decoded = jsonDecode(metadataJson);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid legal metadata');
      }
      String value(String key) =>
          decoded[key] is String ? (decoded[key] as String).trim() : '';
      controller = value('controllerName');
      // The product's public brand can differ from its legal controller.
      name = fallbackAppName.trim();
      if (name.isEmpty) name = value('appName');
      if (name.isEmpty) name = controller;
      email = value('privacyEmail');
      date = value('updatedAt');
      final parsedDate = DateTime.tryParse(date);
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
          parsedDate == null ||
          parsedDate.toIso8601String().substring(0, 10) != date) {
        throw const FormatException('Invalid legal revision date');
      }
      final hex = decoded['themeColor'] == null
          ? '#111c41'
          : value('themeColor');
      if (!RegExp(r'^#[a-fA-F0-9]{6}$').hasMatch(hex)) {
        throw const FormatException('Invalid legal theme color');
      }
      color = 0xff000000 | int.parse(hex.substring(1), radix: 16);
    }
    if (name.isEmpty ||
        controller.isEmpty ||
        !RegExp(
          r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
        ).hasMatch(email)) {
      throw const FormatException('Missing legal identity or contact');
    }
    return LegalDocumentData._(
      appName: name,
      controllerName: controller,
      contactEmail: email,
      updatedAt: date,
      themeColor: color,
      origin: site.replace(path: '/', query: null, fragment: null),
    );
  }

  Uri get privacyUrl => origin.resolve('/politica-de-privacidad/');
  Uri get termsUrl => origin.resolve('/terminos-y-condiciones/');
  Uri get deletionUrl => origin.resolve('/eliminar-cuenta/');

  String render(String markdown) {
    final values = <String, String>{
      'APP_NAME': appName,
      'CONTROLLER_NAME': controllerName,
      'CONTACT_EMAIL': contactEmail,
      'UPDATED_AT': updatedAt,
      'SITE_URL': origin.toString().replaceFirst(RegExp(r'/$'), ''),
      'PRIVACY_URL': privacyUrl.toString(),
      'TERMS_URL': termsUrl.toString(),
      'ACCOUNT_DELETION_URL': deletionUrl.toString(),
    };
    // Braces are reserved for template tokens. Match lone braces too so that
    // truncated or nested tokens cannot silently appear in a public document.
    // Replacements are checked as data and never parsed as another template.
    return markdown.replaceAllMapped(RegExp(r'\{\{[^{}]*\}\}|[{}]'), (match) {
      final token = match.group(0)!;
      if (!token.startsWith('{{') || !token.endsWith('}}')) {
        throw const FormatException('Malformed legal placeholder');
      }
      final value = values[token.substring(2, token.length - 2)];
      if (value == null) {
        throw const FormatException('Unsupported legal placeholder');
      }
      if (RegExp(r'[{}]').hasMatch(value)) {
        throw const FormatException('Nested legal placeholder');
      }
      return value;
    });
  }

  static Uri? _canonicalHttps(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.hasPort && uri.port != 443) ||
        RegExp(r'[\s\\]').hasMatch(value)) {
      return null;
    }
    return uri;
  }
}

/// Executable schemes, relative paths and credential-bearing links are rejected.
Uri? legalLinkUri(String value) {
  if (value.isEmpty || RegExp(r'[\x00-\x20\\]').hasMatch(value)) return null;
  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  if (value.startsWith('#')) {
    return uri.fragment.isNotEmpty && !uri.hasAuthority && uri.path.isEmpty
        ? uri
        : null;
  }
  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty) {
    return uri;
  }
  if (uri.scheme == 'mailto' &&
      !uri.hasAuthority &&
      RegExp(
        r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
      ).hasMatch(uri.path) &&
      !RegExp(r'%0[ad]', caseSensitive: false).hasMatch(value)) {
    return uri;
  }
  return null;
}

String legalHeadingAnchor(String heading) {
  var text = heading.toLowerCase();
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  accents.forEach((key, value) => text = text.replaceAll(key, value));
  return text
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
