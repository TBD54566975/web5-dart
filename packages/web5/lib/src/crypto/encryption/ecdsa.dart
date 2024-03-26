import 'dart:typed_data';

import 'package:web5/src/crypto/jwk/jwk.dart';
import 'package:web5/src/crypto/encryption/secp256k1.dart';

class Ecdsa {
  static const kty = 'EC';

  static Future<Uint8List> sign(Jwk privateKeyJwk, Uint8List payload) {
    if (privateKeyJwk.crv == null) {
      throw Exception('expected jwk to contain crv');
    }

    switch (privateKeyJwk.crv) {
      case Secp256k1.crv:
        return Secp256k1.sign(privateKeyJwk, payload);
      default:
        throw Exception('unsupported crv: ${privateKeyJwk.crv}');
    }
  }

  static Future<void> verify({
    required Jwk publicKey,
    required Uint8List payload,
    required Uint8List signature,
  }) {
    if (publicKey.crv == null) {
      throw Exception('expected jwk to contain crv');
    }

    switch (publicKey.crv) {
      case Secp256k1.crv:
        return Secp256k1.verify(publicKey, payload, signature);
      default:
        throw Exception('unsupported crv: ${publicKey.crv}');
    }
  }

  static String getJwa(Jwk jwk) {
    if (jwk.crv == null) {
      throw Exception('expected jwk to contain crv');
    }

    switch (jwk.crv) {
      case Secp256k1.crv:
        return Secp256k1.alg;
      default:
        throw Exception('unsupported crv: ${jwk.crv}');
    }
  }
}
