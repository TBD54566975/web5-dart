import 'dart:typed_data';

import 'package:tbdex/src/crypto/jwk.dart';

/// Enum [DsaName] representing supported Digital Signature Algorithm (DSA) names.
enum DsaName {
  secp256k1,
  ed25519;

  static final aliases = {
    DsaAlias(algorithm: 'EdDSA', curve: 'Ed25519'): DsaName.ed25519,
    DsaAlias(algorithm: null, curve: 'Ed25519'): DsaName.ed25519,
  };

  static DsaName? findByAlias(DsaAlias alias) => aliases[alias];
}

class DsaAlias {
  String? algorithm;
  String? curve;

  DsaAlias({this.algorithm, this.curve});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DsaAlias &&
        other.algorithm == algorithm &&
        other.curve == curve;
  }

  @override
  int get hashCode => algorithm.hashCode ^ curve.hashCode;
}

/// Abstract interface for Digital Signature Algorithms.
///
/// This interface defines the essential operations for digital signature
/// algorithms including key generation, public key computation from a private
/// key, signing a payload, and verifying a signature. It is designed to be
/// concretely implemented for specific DSA algorithms (e.g. Ed25519)
abstract interface class Dsa {
  DsaName get name;
  String get algorithm;
  String get curve;

  /// generates a private key and returns it as a JWK
  Future<Jwk> generatePrivateKey();

  /// Computes a public key from the private key provided. Applicable for
  /// asymmetric DSA only. Implementers of symmetric key generators should
  /// throw an UnsupportedOperation Exception
  Future<Jwk> computePublicKey(Jwk privateKey);

  /// Signs the given payload using the given private key. Returns the signed
  /// payload as a byte array
  Future<Uint8List> sign(Jwk privateKey, Uint8List payload);

  /// Verifies the given signature provided with the given public key and
  /// payload.
  Future<void> verify(Jwk publicKey, Uint8List payload, Uint8List signature);
}
