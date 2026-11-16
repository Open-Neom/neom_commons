import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class SecurityUtilities {

  /// Returns the sha256 hash of [input] in hex notation.
  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final safeLength =
        (!length.isFinite || length <= 0) ? 32 : length.clamp(1, 4096);
    final random = Random.secure();
    return List.generate(
      safeLength,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

}
