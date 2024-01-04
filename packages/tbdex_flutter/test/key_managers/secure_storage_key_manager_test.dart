import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tbdex/tbdex.dart';
import 'package:tbdex_flutter/src/key_managers/secure_storage_key_manager.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

main() {
  late MockSecureStorage secureStorage;
  late KeyManager keyManager;

  setUp(() {
    secureStorage = MockSecureStorage();
    keyManager = SecureStorageKeyManager(storage: secureStorage);
  });

  group('SecureStorageKeyManager', () {
    test('should generate private key', () async {
      when(() => secureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) => Future.value());

      final thumbprint = await keyManager.generatePrivateKey(DsaName.ed25519);
      expect(thumbprint, isA<String>());

      verify(
        () => secureStorage.write(key: thumbprint, value: any(named: 'value')),
      ).called(1);
    });

    test('getPublicKey should throw exception if private key not found', () {
      when(() => secureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) => Future.value(null));

      expect(keyManager.getPublicKey('bogus'), throwsException);
    });

    test('getPublicKey should return public key', () async {
      final privateKeyJwk =
          await DsaAlgorithms.generatePrivateKey(DsaName.ed25519);
      final privateKeyJwkStr = privateKeyJwk.toString();
      final privateKeyJwkThumbprint = privateKeyJwk.computeThumbprint();

      when(() => secureStorage.read(key: privateKeyJwkThumbprint))
          .thenAnswer((_) => Future.value(privateKeyJwkStr));

      final publicKeyJwk =
          await keyManager.getPublicKey(privateKeyJwkThumbprint);

      final expected = await DsaAlgorithms.computePublicKey(
        Jwk.fromJson(json.decode(privateKeyJwkStr)),
      );

      expect(publicKeyJwk.toJson(), expected.toJson());
    });

    test('sign should throw exception if private key not found', () {
      when(() => secureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) => Future.value(null));

      expect(keyManager.sign('bogus', Uint8List(0)), throwsException);
    });

    test('sign should return signature', () async {
      final privateKeyJwk =
          await DsaAlgorithms.generatePrivateKey(DsaName.ed25519);
      final privateKeyJwkStr = privateKeyJwk.toString();
      final privateKeyJwkThumbprint = privateKeyJwk.computeThumbprint();

      when(() => secureStorage.read(key: privateKeyJwkThumbprint))
          .thenAnswer((_) => Future.value(privateKeyJwkStr));

      final signature =
          await keyManager.sign(privateKeyJwkThumbprint, Uint8List(0));

      final expected = await DsaAlgorithms.sign(
        Jwk.fromJson(json.decode(privateKeyJwkStr)),
        Uint8List(0),
      );

      expect(signature, expected);
    });
  });
}
