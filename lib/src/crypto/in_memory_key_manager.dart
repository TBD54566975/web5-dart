import 'dart:collection';
import 'dart:typed_data';

import 'package:tbdex/src/crypto/dsa.dart';
import 'package:tbdex/src/crypto/jwk.dart';
import 'package:tbdex/src/crypto/ed25519.dart';
import 'package:tbdex/src/crypto/key_manager.dart';

final supportedAlgorithms = {DsaName.ed25519: Ed25519()};

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
  final HashMap<String, Jwk> keyStore = HashMap();

  @override
  Future<String> generatePrivateKey(DsaName alg) async {
    if (!supportedAlgorithms.containsKey(alg)) {
      throw Exception("${alg.name} not supported");
    }

    final keyGenerator = supportedAlgorithms[alg];
    final privateKeyJwk = await keyGenerator!.generatePrivateKey();

    final alias = privateKeyJwk.computeThumbprint();
    keyStore[alias] = privateKeyJwk;

    return alias;
  }

  @override
  Future<Jwk> getPublicKey(String keyAlias) async {
    if (!keyStore.containsKey(keyAlias)) {
      throw Exception("key with alias $keyAlias not found.");
    }

    final privateKeyJwk = keyStore[keyAlias]!;

    final dsaName = DsaName.findByAlias(
      DsaAlias(algorithm: privateKeyJwk.alg, curve: privateKeyJwk.crv),
    );

    if (dsaName == null) {
      throw Exception(
        "${privateKeyJwk.alg}:${privateKeyJwk.crv} not supported.",
      );
    }

    final keyGenerator = supportedAlgorithms[dsaName]!;
    final publicKeyJwk = await keyGenerator.computePublicKey(privateKeyJwk);

    return publicKeyJwk;
  }

  @override
  Future<Uint8List> sign(String keyAlias, Uint8List payload) async {
    if (!keyStore.containsKey(keyAlias)) {
      throw Exception("key with alias $keyAlias not found.");
    }

    final privateKeyJwk = keyStore[keyAlias]!;
    final dsaName = DsaName.findByAlias(
      DsaAlias(algorithm: privateKeyJwk.alg, curve: privateKeyJwk.crv),
    );

    if (dsaName != null) {
      throw Exception(
        "DSA ${privateKeyJwk.alg}:${privateKeyJwk.crv} not supported.",
      );
    }

    final signer = supportedAlgorithms[dsaName]!;
    final signatureBytes = await signer.sign(privateKeyJwk, payload);

    return signatureBytes;
  }
}
