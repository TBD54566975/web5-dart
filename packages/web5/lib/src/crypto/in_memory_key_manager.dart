import 'dart:typed_data';

import 'package:web5/src/crypto/algorithm_id.dart';
import 'package:web5/src/crypto/jwk.dart';
import 'package:web5/src/crypto/key_manager.dart';
import 'package:web5/src/crypto/crypto.dart';

/// A class for managing cryptographic keys in-memory.
///
/// [InMemoryKeyManager] is an implementation of [KeyManager] that stores keys
/// in-memory using a mutable map. It provides methods to:
/// - Generate private keys ([generatePrivateKey])
/// - Retrieve public keys ([getPublicKey])
/// - Sign payloads ([sign])
///
/// Example:
/// ```dart
/// final keyManager = InMemoryKeyManager();
/// final keyAlias = await keyManager.generatePrivateKey(DsaName.ed25519);
/// final signatureBytes = await keyManager.sign(keyAlias, Uint8List.fromList([20, 32]));
/// ```
///
class InMemoryKeyManager implements KeyManager, KeyImporter, KeyExporter {
  final Map<String, Jwk> _keyStore = {};

  @override
  Future<String> generatePrivateKey(AlgorithmId algId) async {
    final privateKeyJwk = await Crypto.generatePrivateKey(algId);
    final alias = privateKeyJwk.computeThumbprint();

    _keyStore[alias] = privateKeyJwk;

    return alias;
  }

  @override
  Future<Jwk> getPublicKey(String keyId) async =>
      Crypto.computePublicKey(_retrievePrivateKeyJwk(keyId));

  @override
  Future<Uint8List> sign(String keyAlias, Uint8List payload) async {
    final privateKeyJwk = _retrievePrivateKeyJwk(keyAlias);
    return Crypto.sign(privateKeyJwk, payload);
  }

  Jwk _retrievePrivateKeyJwk(String keyAlias) {
    final privateKeyJwk = _keyStore[keyAlias];
    if (privateKeyJwk == null) {
      throw Exception('key with alias $keyAlias not found.');
    }

    return privateKeyJwk;
  }

  @override
  Future<Jwk> export(String keyId) {
    if (_keyStore.containsKey(keyId)) {
      return Future.value(_keyStore[keyId]);
    } else {
      return Future.error('Key not found');
    }
  }

  @override
  Future<String> import(Jwk jwk) {
    final keyId = jwk.computeThumbprint();
    _keyStore[keyId] = jwk;

    return Future.value(keyId);
  }
}
