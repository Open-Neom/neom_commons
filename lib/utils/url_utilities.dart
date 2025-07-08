
// import 'dart:html' as html;
// import 'dart:html' as html;

import 'package:neom_core/utils/constants/url_constants.dart';


class UrlUtilities {

  static String getYouTubeUrl(String text) {
    RegExp regExp = RegExp(
        r'((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?'
    );
    // RegExp regExp = RegExp(
    //     r'(?<!music\.)((?:https?:)?\/\/)?((?:www|m)\.)?(youtube\.com|youtu\.be)(\/(?:watch\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?'
    // );
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

}
