// Tests for `UrlUtilities`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/url_utilities.dart';

void main() {
  group('getYouTubeUrl', () {
    test('extrae URL completa de YouTube', () {
      expect(
        UrlUtilities.getYouTubeUrl('Mira esto: https://youtube.com/watch?v=abc123'),
        contains('youtube.com'),
      );
    });

    test('extrae URL corta youtu.be', () {
      expect(
        UrlUtilities.getYouTubeUrl('https://youtu.be/abc123'),
        contains('youtu.be'),
      );
    });

    test('texto sin URL de YouTube devuelve ""', () {
      expect(UrlUtilities.getYouTubeUrl('Hola mundo'), '');
    });
  });

  group('getSpotifyUrl', () {
    test('extrae URL de track de Spotify', () {
      const url = 'https://open.spotify.com/track/abc123XYZ';
      expect(UrlUtilities.getSpotifyUrl(url), url);
    });

    test('texto sin URL de Spotify devuelve ""', () {
      expect(UrlUtilities.getSpotifyUrl('Hola'), '');
    });
  });

  group('getUrlFromText', () {
    test('extrae primera URL del texto', () {
      expect(
        UrlUtilities.getUrlFromText('Visita https://example.com gracias'),
        'https://example.com',
      );
    });

    test('texto sin URL devuelve ""', () {
      expect(UrlUtilities.getUrlFromText('Hola'), '');
    });

    test('soporta URLs con paths y queries', () {
      final url = UrlUtilities.getUrlFromText(
        'Aquí: https://x.com/path?q=1&v=2 fin',
      );
      expect(url, contains('x.com/path'));
    });
  });

  group('removeQueryParameters', () {
    test('URL sin query se mantiene', () {
      expect(
        UrlUtilities.removeQueryParameters('https://x.com/path'),
        'https://x.com/path',
      );
    });

    test('URL con query: se remueve desde el ?', () {
      expect(
        UrlUtilities.removeQueryParameters('https://x.com/path?v=1&q=2'),
        'https://x.com/path',
      );
    });

    test('URL solo con query: queda dominio sólo', () {
      expect(
        UrlUtilities.removeQueryParameters('https://x.com?v=1'),
        'https://x.com',
      );
    });
  });
}
