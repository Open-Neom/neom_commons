import 'dart:typed_data';

abstract class ICipherService {
  /// Generates or loads the persistent Curve25519 and Ed25519 keys
  Future<void> initializeKeys();

  /// Gets the user's public identity fingerprint (SHA-256 hash of public key)
  Future<String> getFingerprint();

  /// Encrypts raw message payload bytes using the session ciphers for a specific peer
  Future<Uint8List> encryptPayload(Uint8List payload, {String? peerId});

  /// Decrypts raw message payload bytes using the session ciphers for a specific peer
  Future<Uint8List> decryptPayload(Uint8List encryptedPayload, {String? peerId});

  /// Serializes and pads (PKCS#7) data into a structured BitChat binary packet
  Future<Uint8List> serializePacket({
    required int type,
    required int routeId,
    required int ttl,
    required int seqId,
    required int timestamp,
    required Uint8List payload,
    String? recipientId,
  });

  /// Deserializes a binary packet, verifying checksums and removing PKCS#7 padding
  Future<Map<String, dynamic>> deserializePacket(Uint8List rawBytes);
}
