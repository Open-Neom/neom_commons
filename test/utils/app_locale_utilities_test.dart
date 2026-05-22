// Tests for `AppLocaleUtilities`.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/app_locale_utilities.dart';
import 'package:neom_core/utils/enums/app_locale.dart';

void main() {
  group('AppLocaleUtilities.languageFromLocale', () {
    test('en → english', () {
      expect(
        AppLocaleUtilities.languageFromLocale(const Locale('en')),
        AppLocale.english.name,
      );
    });

    test('es → spanish', () {
      expect(
        AppLocaleUtilities.languageFromLocale(const Locale('es')),
        AppLocale.spanish.name,
      );
    });

    test('esp → spanish (alias legacy)', () {
      expect(
        AppLocaleUtilities.languageFromLocale(const Locale('esp')),
        AppLocale.spanish.name,
      );
    });

    test('fr → french', () {
      expect(
        AppLocaleUtilities.languageFromLocale(const Locale('fr')),
        AppLocale.french.name,
      );
    });

    test('de → deutsch', () {
      expect(
        AppLocaleUtilities.languageFromLocale(const Locale('de')),
        AppLocale.deutsch.name,
      );
    });

    test('código no soportado → "" (default sin match)', () {
      // OBS: el método devuelve cadena vacía para idiomas no soportados.
      // Si la app usa esto sin validar, podría mostrar UI vacía.
      expect(
        AppLocaleUtilities.languageFromLocale(const Locale('zh')),
        '',
      );
    });

    test('locale con countryCode no afecta resultado', () {
      // Solo se mira languageCode
      expect(
        AppLocaleUtilities.languageFromLocale(const Locale('es', 'MX')),
        AppLocale.spanish.name,
      );
      expect(
        AppLocaleUtilities.languageFromLocale(const Locale('en', 'US')),
        AppLocale.english.name,
      );
    });
  });
}
