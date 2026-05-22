// Tests for `TextUtilities`.
// NOTA: omitimos métodos que dependen de Sint.locale o AppConfig.logger.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/text_utilities.dart';

void main() {
  group('TextUtilities.normalizeString', () {
    test('quita acentos en vocales', () {
      expect(TextUtilities.normalizeString('áéíóú'), 'aeiou');
      expect(TextUtilities.normalizeString('ÁÉÍÓÚ'), 'AEIOU');
    });

    test('quita acentos graves, circunflejos, diéresis', () {
      expect(TextUtilities.normalizeString('àèìòù'), 'aeiou');
      expect(TextUtilities.normalizeString('âêîôû'), 'aeiou');
      expect(TextUtilities.normalizeString('äëïöü'), 'aeiou');
    });

    test('ñ → n', () {
      expect(TextUtilities.normalizeString('niño'), 'nino');
      expect(TextUtilities.normalizeString('Niño'), 'Nino');
    });

    test('ç → c', () {
      expect(TextUtilities.normalizeString('Français'), 'Francais');
    });

    test('texto sin acentos se mantiene igual', () {
      expect(TextUtilities.normalizeString('hello world'), 'hello world');
    });

    test('cadena vacía → vacía', () {
      expect(TextUtilities.normalizeString(''), '');
    });
  });

  group('TextUtilities.capitalizeFirstLetter', () {
    test('cadena vacía → vacía', () {
      expect(TextUtilities.capitalizeFirstLetter(''), '');
    });

    test('una letra mayúscula', () {
      expect(TextUtilities.capitalizeFirstLetter('a'), 'A');
    });

    test('palabra capitaliza solo la primera', () {
      expect(TextUtilities.capitalizeFirstLetter('hola'), 'Hola');
    });

    test('frase capitaliza solo el primer carácter', () {
      expect(
        TextUtilities.capitalizeFirstLetter('hola mundo'),
        'Hola mundo',
      );
    });

    test('ya capitalizada se preserva', () {
      expect(TextUtilities.capitalizeFirstLetter('Hola'), 'Hola');
    });
  });

  group('TextUtilities.capitalizeAllWordsFirstLetter', () {
    test('vacía → vacía', () {
      expect(TextUtilities.capitalizeAllWordsFirstLetter(''), '');
      expect(TextUtilities.capitalizeAllWordsFirstLetter('   '), '');
    });

    test('una letra → mayúscula', () {
      expect(TextUtilities.capitalizeAllWordsFirstLetter('a'), 'A');
    });

    test('una palabra → capitalizada', () {
      expect(
        TextUtilities.capitalizeAllWordsFirstLetter('hola'),
        'Hola',
      );
    });

    test('múltiples palabras → cada una capitalizada', () {
      expect(
        TextUtilities.capitalizeAllWordsFirstLetter('hola mundo cruel'),
        'Hola Mundo Cruel',
      );
    });

    test('mayúsculas en input se respetan al final', () {
      expect(
        TextUtilities.capitalizeAllWordsFirstLetter('GETX WILL MAKE IT EASY'),
        'Getx Will Make It Easy',
      );
    });

    test('múltiples espacios entre palabras se colapsan', () {
      expect(
        TextUtilities.capitalizeAllWordsFirstLetter('hola    mundo'),
        'Hola Mundo',
      );
    });

    test('trim de espacios al inicio y al final', () {
      expect(
        TextUtilities.capitalizeAllWordsFirstLetter('  hola mundo  '),
        'Hola Mundo',
      );
    });
  });

  group('TextUtilities.removeAllWhitespace', () {
    test('quita todos los espacios', () {
      expect(TextUtilities.removeAllWhitespace('hola mundo'), 'holamundo');
    });

    test('cadena sin espacios queda igual', () {
      expect(TextUtilities.removeAllWhitespace('foo'), 'foo');
    });

    test('cadena vacía → vacía', () {
      expect(TextUtilities.removeAllWhitespace(''), '');
    });

    test('solo espacios → vacía', () {
      expect(TextUtilities.removeAllWhitespace('     '), '');
    });

    test('NO quita tabs ni newlines (solo espacios)', () {
      // El método solo reemplaza ' ', no tabs/newlines.
      expect(TextUtilities.removeAllWhitespace('a\tb\nc'), 'a\tb\nc');
    });
  });

  group('TextUtilities.getArtistName', () {
    test('"Artist - Track" devuelve "Artist"', () {
      expect(TextUtilities.getArtistName('Artist - Track'), 'Artist');
    });

    test('cadena sin "-" devuelve la cadena trim', () {
      expect(TextUtilities.getArtistName('Just Title'), 'Just Title');
    });

    test('cadena vacía → ""', () {
      expect(TextUtilities.getArtistName(''), '');
    });

    test('múltiples "-" toma el primero como artista', () {
      expect(
        TextUtilities.getArtistName('Artist - Track - Remix'),
        'Artist',
      );
    });
  });

  group('TextUtilities.getMediaName', () {
    test('"Artist - Track" devuelve "Track"', () {
      expect(TextUtilities.getMediaName('Artist - Track'), 'Track');
    });

    test('"Artist - Track - Remix" devuelve "Track - Remix"', () {
      expect(
        TextUtilities.getMediaName('Artist - Track - Remix'),
        'Track - Remix',
      );
    });

    test('cadena sin "-" devuelve la cadena (caso degenerado)', () {
      // Caso límite: cuando length == 1, toma el último (que es el único).
      expect(TextUtilities.getMediaName('Just Title'), 'Just Title');
    });
  });
}
