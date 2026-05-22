// Tests for enums en neom_commons/utils/enums/.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/enums/app_drawer_menu.dart';
import 'package:neom_commons/utils/enums/dot_menu_choices.dart';
import 'package:neom_commons/utils/enums/image_quality.dart';
import 'package:neom_commons/utils/enums/yes_no.dart';

void main() {
  group('AppDrawerMenu enum', () {
    test('value es igual al name del enum', () {
      for (final menu in AppDrawerMenu.values) {
        expect(menu.value, menu.name);
      }
    });

    test('valores específicos esperados', () {
      expect(AppDrawerMenu.profile.value, 'profile');
      expect(AppDrawerMenu.events.value, 'events');
      expect(AppDrawerMenu.logout.value, 'logout');
      expect(AppDrawerMenu.erp.value, 'erpDashboard');
    });

    test('contiene los items principales del menú', () {
      final names = AppDrawerMenu.values.map((m) => m.name).toSet();
      expect(names, containsAll([
        'profile', 'events', 'inbox', 'calendar',
        'wallet', 'settings', 'logout',
      ]));
    });

    test('todos los values son únicos', () {
      final values = AppDrawerMenu.values.map((m) => m.value).toSet();
      expect(values.length, AppDrawerMenu.values.length);
    });
  });

  group('DotMenuChoices enum', () {
    test('tiene al menos 1 valor', () {
      expect(DotMenuChoices.values, isNotEmpty);
    });

    test('todos los valores son distinguibles', () {
      final names = DotMenuChoices.values.map((c) => c.name).toSet();
      expect(names.length, DotMenuChoices.values.length);
    });
  });

  group('ImageQuality enum', () {
    test('tiene valores definidos', () {
      expect(ImageQuality.values, isNotEmpty);
    });
  });

  group('YesNo enum', () {
    test('tiene valores definidos', () {
      expect(YesNo.values, isNotEmpty);
    });

    test('todos los valores son únicos', () {
      final names = YesNo.values.map((y) => y.name).toSet();
      expect(names.length, YesNo.values.length);
    });
  });
}
