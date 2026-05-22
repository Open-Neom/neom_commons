// Tests for `SecurityUtilities`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/security_utilities.dart';

void main() {
  group('SecurityUtilities.sha256ofString', () {
    test('cadena vacía produce hash conocido', () {
      // SHA-256 de "" = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
      expect(
        SecurityUtilities.sha256ofString(''),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('"hello" produce hash conocido', () {
      expect(
        SecurityUtilities.sha256ofString('hello'),
        '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
      );
    });

    test('mismo input produce mismo hash (determinismo)', () {
      final h1 = SecurityUtilities.sha256ofString('foo');
      final h2 = SecurityUtilities.sha256ofString('foo');
      expect(h1, h2);
    });

    test('inputs distintos producen hashes distintos', () {
      final h1 = SecurityUtilities.sha256ofString('a');
      final h2 = SecurityUtilities.sha256ofString('b');
      expect(h1, isNot(h2));
    });

    test('output siempre es 64 caracteres hex', () {
      expect(SecurityUtilities.sha256ofString('').length, 64);
      expect(SecurityUtilities.sha256ofString('x').length, 64);
      expect(SecurityUtilities.sha256ofString('a' * 1000).length, 64);
    });

    test('soporta caracteres unicode', () {
      // No debe crashear con emojis ni ñ
      expect(
        () => SecurityUtilities.sha256ofString('ñ🎵'),
        returnsNormally,
      );
    });
  });

  group('SecurityUtilities.generateNonce', () {
    test('default length 32', () {
      expect(SecurityUtilities.generateNonce().length, 32);
    });

    test('length custom respetada', () {
      expect(SecurityUtilities.generateNonce(16).length, 16);
      expect(SecurityUtilities.generateNonce(64).length, 64);
    });

    test('nonces consecutivos son distintos (random.secure)', () {
      final n1 = SecurityUtilities.generateNonce();
      final n2 = SecurityUtilities.generateNonce();
      // Ultra rara colisión con 64 caracteres aleatorios.
      expect(n1, isNot(n2));
    });

    test('solo contiene caracteres del charset', () {
      const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZ'
          'abcdefghijklmnopqrstuvwxyz-._';
      final nonce = SecurityUtilities.generateNonce(100);
      for (final c in nonce.split('')) {
        expect(charset.contains(c), isTrue,
            reason: 'caracter "$c" no está en el charset permitido');
      }
    });
  });
}
