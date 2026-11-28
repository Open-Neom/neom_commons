import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/data/translations/core/core_de_translations.dart';
import 'package:neom_commons/data/translations/core/core_en_translations.dart';
import 'package:neom_commons/data/translations/core/core_es_translations.dart';
import 'package:neom_commons/data/translations/core/core_fr_translations.dart';
import 'package:neom_commons/utils/external_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/event_type.dart';

void main() {
  late AppInUse previousApp;

  setUp(() {
    previousApp = AppConfig.instance.appInUse;
  });

  tearDown(() {
    AppConfig.instance.appInUse = previousApp;
  });

  group('AppFlavour.getEventTypes for Gigmeout', () {
    test('returns only the 6 music-relevant event types including jamming', () {
      AppConfig.instance.appInUse = AppInUse.g;
      final types = AppFlavour.getEventTypes(forCreation: true);
      expect(types, const [
        EventType.rehearsal,
        EventType.gig,
        EventType.jamming,
        EventType.festival,
        EventType.masterclass,
        EventType.lesson,
      ]);
      expect(types, isNot(contains(EventType.meetup)));
      expect(types, isNot(contains(EventType.talk)));
      expect(types, isNot(contains(EventType.virtualMeeting)));
      expect(types, isNot(contains(EventType.bookTour)));
    });
  });

  group('ExternalUtilities.buildSafeWhatsappUri', () {
    test('normalizes legacy whatsapp://send template to HTTPS', () {
      final uri = ExternalUtilities.buildSafeWhatsappUri(
        templateUrl: 'whatsapp://send?phone=<phoneNumber>&text=<message>',
        phone: '+52 33 1234 5678',
        message: 'Hola banda!',
      );
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'api.whatsapp.com');
      expect(uri.queryParameters['phone'], '523312345678');
      expect(uri.queryParameters['text'], 'Hola banda!');
    });

    test('supports https://wa.me template directly', () {
      final uri = ExternalUtilities.buildSafeWhatsappUri(
        templateUrl: 'https://wa.me/<phoneNumber>?text=<message>',
        phone: '+52 33 1234 5678',
        message: 'Hola',
      );
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/523312345678');
    });
  });

  group('Core translations for Gigmeout 4.0.1 fixes', () {
    test('fixes meetup typo and adds learning + business across all locales', () {
      expect(CoreEsTranslations.values['meetup'], 'Encuentro');
      expect(CoreEsTranslations.values['learning'], 'Aprendizaje');
      expect(CoreEsTranslations.values['business'], 'Negocios');
      expect(CoreEnTranslations.values['learning'], 'Learning');
      expect(CoreEnTranslations.values['business'], 'Business');
      expect(CoreFrTranslations.values['learning'], 'Apprentissage');
      expect(CoreFrTranslations.values['business'], 'Entreprises');
      expect(CoreDeTranslations.values['learning'], 'Lernen');
      expect(CoreDeTranslations.values['business'], 'Geschäft');
    });
  });
}
