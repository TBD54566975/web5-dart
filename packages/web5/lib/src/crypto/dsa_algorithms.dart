import 'dart:typed_data';

import 'package:web5/web5.dart';

class DsaAlgorithms {
  static final _supportedAlgorithms = {
    DsaName.ed25519: Ed25519(),
    DsaName.secp256k1: Secp256k1(),
  };

  static Future<Jwk> generatePrivateKey(DsaName alg) {
    final dsa = _supportedAlgorithms[alg];

    if (dsa == null) {
      throw Exception("${alg.name} not supported");
    }

    return dsa.generatePrivateKey();
  }

  static Future<Jwk> computePublicKey(Jwk privateKeyJwk) {
    return _getDsa(privateKeyJwk).computePublicKey(privateKeyJwk);
  }

  static Future<Uint8List> sign(Jwk privateKeyJwk, Uint8List payload) {
    return _getDsa(privateKeyJwk).sign(privateKeyJwk, payload);
  }

  static Future<void> verify({
    required DsaName algName,
    required Jwk publicKey,
    required Uint8List payload,
    required Uint8List signature,
  }) {
    final dsa = _supportedAlgorithms[algName];
    if (dsa == null) {
      throw Exception(
        "DSA ${algName.algorithm}:${algName.curve} not supported.",
      );
    }

    return dsa.verify(publicKey, payload, signature);
  }

  static Dsa _getDsa(Jwk privateKeyJwk) {
    final dsa = _supportedAlgorithms[DsaName.findByAlias(
      algorithm: privateKeyJwk.alg,
      curve: privateKeyJwk.crv,
    )];

    if (dsa == null) {
      throw Exception(
        "DSA ${privateKeyJwk.alg}:${privateKeyJwk.crv} not supported.",
      );
    }
    return dsa;
  }
}
