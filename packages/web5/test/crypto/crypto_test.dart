import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:web5/src/crypto.dart';

void main() {
  group('generatePrivateKey', () {
    test('should generate a secp256k1 private key when specified', () async {
      final jwk = await Crypto.generatePrivateKey(AlgorithmId.secp256k1);
      expect(jwk, isNotNull);
      expect(jwk.kty, Secp256k1.kty);
      expect(jwk.crv, Secp256k1.crv);
    });

    test('should generate an ed25519 test when specified', () async {
      final jwk = await Crypto.generatePrivateKey(AlgorithmId.ed25519);
      expect(jwk, isNotNull);
      expect(jwk.kty, Ed25519.kty);
      expect(jwk.crv, Ed25519.crv);
    });
  });

  group('sign', () {
    test('should throw an exception if kty isnt supported', () async {
      final jwk = Jwk(kty: 'YOLO');

      expect(
        () async {
          await Crypto.sign(jwk, utf8.encode('hello'));
        },
        throwsA(isA<Exception>()),
      );
    });

    test('should throw an exception if crv is not supported', () async {
      final jwk = Jwk(kty: 'EC', crv: 'YOLO');

      expect(
        () async {
          await Crypto.sign(jwk, utf8.encode('hello'));
        },
        throwsA(isA<Exception>()),
      );
    });

    test('should be able to sign a message with a secp256k1 key', () async {
      final jwk = await Crypto.generatePrivateKey(AlgorithmId.secp256k1);
      final signature = await Crypto.sign(jwk, utf8.encode('hello'));
      expect(signature, isNotNull);
    });

    test('should be able to sign a message with an ed25519 key', () async {
      final jwk = await Crypto.generatePrivateKey(AlgorithmId.ed25519);
      final signature = await Crypto.sign(jwk, utf8.encode('hello'));
      expect(signature, isNotNull);
    });
  });

  group('verify', () {});

  group('getJwa', () {});
}
