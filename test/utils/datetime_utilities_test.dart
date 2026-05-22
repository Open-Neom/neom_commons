// Tests for `DateTimeUtilities` (sin tocar formatTimeAgo que requiere SINT init).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/datetime_utilities.dart';

void main() {
  group('getDaysFromNow', () {
    test('default 28 días + hoy = 29 elementos', () {
      final dates = DateTimeUtilities.getDaysFromNow();
      expect(dates.length, 29);
    });

    test('días custom: 7 → 8 elementos (incluye hoy)', () {
      expect(DateTimeUtilities.getDaysFromNow(days: 7).length, 8);
    });

    test('0 días devuelve solo hoy', () {
      expect(DateTimeUtilities.getDaysFromNow(days: 0).length, 1);
    });

    test('fechas son secuenciales (cada una +1 día)', () {
      final dates = DateTimeUtilities.getDaysFromNow(days: 3);
      for (var i = 1; i < dates.length; i++) {
        final diff = dates[i].difference(dates[i - 1]);
        expect(diff.inDays, 1);
      }
    });
  });

  group('getDurationInMinutes', () {
    test('0 ms → "00:00"', () {
      expect(DateTimeUtilities.getDurationInMinutes(0), '00:00');
    });

    test('30000 ms (30s) → "00:30"', () {
      expect(DateTimeUtilities.getDurationInMinutes(30000), '00:30');
    });

    test('60000 ms (1 min) → "01:00"', () {
      expect(DateTimeUtilities.getDurationInMinutes(60000), '01:00');
    });

    test('125000 ms (2m 5s) → "02:05"', () {
      expect(DateTimeUtilities.getDurationInMinutes(125000), '02:05');
    });

    test('60 minutos exactos → "00:00" (mod 60)', () {
      // 1 hora = 3600000 ms — minutes mod 60 = 0
      expect(DateTimeUtilities.getDurationInMinutes(3600000), '00:00');
    });
  });

  group('secondsToMinutes (clockView=true)', () {
    test('0 segundos → "00:00"', () {
      expect(DateTimeUtilities.secondsToMinutes(0), '00:00');
    });

    test('30 → "00:30"', () {
      expect(DateTimeUtilities.secondsToMinutes(30), '00:30');
    });

    test('60 → "01:00"', () {
      expect(DateTimeUtilities.secondsToMinutes(60), '01:00');
    });

    test('125 → "02:05"', () {
      expect(DateTimeUtilities.secondsToMinutes(125), '02:05');
    });

    test('padding de 0 leading', () {
      expect(DateTimeUtilities.secondsToMinutes(5), '00:05');
      expect(DateTimeUtilities.secondsToMinutes(65), '01:05');
    });

    test('hora exacta en minutos solamente (no h:mm:ss)', () {
      // 3600s = 60 minutos = "60:00"
      expect(DateTimeUtilities.secondsToMinutes(3600), '60:00');
    });
  });

  group('isWithinLastSevenDays', () {
    test('fecha de ahora está dentro', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(DateTimeUtilities.isWithinLastSevenDays(now), isTrue);
    });

    test('fecha de hace 3 días está dentro', () {
      final past = DateTime.now()
          .subtract(const Duration(days: 3))
          .millisecondsSinceEpoch;
      expect(DateTimeUtilities.isWithinLastSevenDays(past), isTrue);
    });

    test('fecha de hace 8 días está fuera', () {
      final past = DateTime.now()
          .subtract(const Duration(days: 8))
          .millisecondsSinceEpoch;
      expect(DateTimeUtilities.isWithinLastSevenDays(past), isFalse);
    });

    test('fecha de hace 7 días está fuera (`< 7`, no `<= 7`)', () {
      final past = DateTime.now()
          .subtract(const Duration(days: 7, hours: 1))
          .millisecondsSinceEpoch;
      expect(DateTimeUtilities.isWithinLastSevenDays(past), isFalse);
    });
  });
}
