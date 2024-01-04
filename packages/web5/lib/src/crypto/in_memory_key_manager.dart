import 'dart:typed_data';

import 'package:web5/src/crypto/dsa.dart';
import 'package:web5/src/crypto/dsa_algorithms.dart';
import 'package:web5/src/crypto/jwk.dart';
import 'package:web5/src/crypto/key_manager.dart';

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
class InMemoryKeyManager implements KeyManager {
  final Map<String, Jwk> _keyStore = {};

  @override
  Future<String> generatePrivateKey(DsaName alg) async {
    final privateKeyJwk = await DsaAlgorithms.generatePrivateKey(alg);
    final alias = privateKeyJwk.computeThumbprint();

    _keyStore[alias] = privateKeyJwk;

    return alias;
  }

  @override
  Future<Jwk> getPublicKey(String keyAlias) async =>
      DsaAlgorithms.computePublicKey(_retrievePrivateKeyJwk(keyAlias));

  @override
  Future<Uint8List> sign(String keyAlias, Uint8List payload) async {
    final privateKeyJwk = _retrievePrivateKeyJwk(keyAlias);
    return DsaAlgorithms.sign(privateKeyJwk, payload);
  }

  Jwk _retrievePrivateKeyJwk(String keyAlias) {
    final privateKeyJwk = _keyStore[keyAlias];
    if (privateKeyJwk == null) {
      throw Exception("key with alias $keyAlias not found.");
    }

    return privateKeyJwk;
  }
}
