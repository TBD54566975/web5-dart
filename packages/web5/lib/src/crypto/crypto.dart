import 'dart:typed_data';

import 'package:web5/src/crypto/algorithm_id.dart';
import 'package:web5/src/crypto/ecdsa.dart';
import 'package:web5/src/crypto/eddsa.dart';
import 'package:web5/src/crypto/jwk.dart';
import 'package:web5/src/crypto/ed25519.dart';
import 'package:web5/src/crypto/secp256k1.dart';

class Crypto {
  static Future<Jwk> generatePrivateKey(AlgorithmId algId) {
    switch (algId) {
      case AlgorithmId.ed25519:
        return Ed25519.generatePrivateKey();
      case AlgorithmId.secp256k1:
        return Secp256k1.generatePrivateKey();
    }
  }

  static Future<Jwk> computePublicKey(Jwk privateKeyJwk) {
    switch (privateKeyJwk.kty) {
      case Ed25519.kty:
        return Ed25519.computePublicKey(privateKeyJwk);
      case Secp256k1.kty:
        return Secp256k1.computePublicKey(privateKeyJwk);
      default:
        throw Exception('unsupported kty: ${privateKeyJwk.kty}');
    }
  }

  static Jwk bytesToPublicKey(AlgorithmId algId, Uint8List bytes) {
    switch (algId) {
      case AlgorithmId.ed25519:
        return Ed25519.bytesToPublicKey(bytes);
      case AlgorithmId.secp256k1:
        return Secp256k1.bytesToPublicKey(bytes);
    }
  }

  static Future<Uint8List> sign(Jwk privateKeyJwk, Uint8List payload) {
    switch (privateKeyJwk.kty) {
      case Ecdsa.kty:
        return Ecdsa.sign(privateKeyJwk, payload);
      case Eddsa.kty:
        return Eddsa.sign(privateKeyJwk, payload);
      default:
        throw Exception('unsupported kty: ${privateKeyJwk.kty}');
    }
  }

  static Future<void> verify({
    required Jwk publicKey,
    required Uint8List payload,
    required Uint8List signature,
  }) {
    switch (publicKey.kty) {
      case Ecdsa.kty:
        return Ecdsa.verify(
          publicKey: publicKey,
          payload: payload,
          signature: signature,
        );
      case Eddsa.kty:
        return Eddsa.verify(
          publicKey: publicKey,
          payload: payload,
          signature: signature,
        );
      default:
        throw Exception('unsupported kty: ${publicKey.kty}');
    }
  }

  static String getJwa(Jwk jwk) {
    switch (jwk.kty) {
      case Ecdsa.kty:
        return Ecdsa.getJwa(jwk);
      case Eddsa.kty:
        return Eddsa.getJwa(jwk);
      default:
        throw Exception('unsupported kty: ${jwk.kty}');
    }
  }
}
