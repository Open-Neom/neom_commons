
// import 'dart:html' as html;
// import 'dart:html' as html;

import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/constants/url_constants.dart';


class UrlUtilities {

  static String getYouTubeUrl(String text) {
    RegExp regExp = RegExp(
        r'((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?'
    );

    String? matches = regExp.stringMatch(text);
    if (matches == null) return ''; /// Always returns here while the video URL is in the content parameter

    final String youTubeUrl = matches;
    return youTubeUrl;
  }

  static String getSpotifyUrl(String text) {
    RegExp regExp = RegExp(
        r'(https:\/\/open.spotify.com\/track\/[a-zA-Z0-9]+)|(open.spotify.com\/track\/[a-zA-Z0-9]+)|(spotify.com\/track\/[a-zA-Z0-9]+)'
    );

    String? matches = regExp.stringMatch(text);
    if (matches == null) return ''; /// Always returns here while the track URL is in the content parameter

    final String spotifyUrl = matches;
    return spotifyUrl;
  }

  static String getUrlFromText(String text) {
    RegExp urlRegex = RegExp(r'(https?://[^\s]+)');

    String? matches = urlRegex.stringMatch(text);
    if (matches == null) return '';

    final String url = matches;
    return url;
  }

  static String removeQueryParameters(String url) {
    final int questionMarkIndex = url.indexOf('?');
    if (questionMarkIndex == -1) {
      return url;
    }

    return url.substring(0, questionMarkIndex);
  }

  static bool isExternalDomain(String url) {
    final uri = Uri.parse(url);
    return UrlConstants.externalDomains.contains(uri.host);
  }

  static bool isValidExternalDomain(String url) {
    AppConfig.logger.d('Validating URL: $url');

    // 1. Normalización: Si el usuario escribió "youtube.com", le agregamos "https://"
    // Esto es vital para que Uri.parse funcione correctamente.
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    // 2. Validación Nativa (Más confiable que Regex para URLs modernas)
    // Uri.tryParse maneja mejor rutas complejas como /@usuario o query params (?v=xyz)
    final uri = Uri.tryParse(url);

    // Verificamos que tenga esquema (http/s) y un host (dominio) válido con al menos un punto
    bool isValid = uri != null &&
        uri.hasScheme &&
        uri.host.isNotEmpty &&
        (uri.host.contains('.') || uri.host == 'localhost') &&
        !uri.host.endsWith('.');

    AppConfig.logger.d('URL is valid: $isValid');
    return isValid;
  }

}
