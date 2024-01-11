import 'dart:typed_data';

import 'package:web5/src/crypto/jwk.dart';
import 'package:web5/src/crypto/dsa_name.dart';

/// Abstract interface for Digital Signature Algorithms.
///
/// This interface defines the essential operations for digital signature
/// algorithms including key generation, public key computation from a private
/// key, signing a payload, and verifying a signature. It is designed to be
/// concretely implemented for specific DSA algorithms (e.g. Ed25519)
abstract interface class Dsa {
  DsaName get name;

  /// [JOSE kty](https://www.iana.org/assignments/jose/jose.xhtml)
  String get keyType;

  /// [JOSE alg](https://www.iana.org/assignments/jose/jose.xhtml)
  String get algorithm;

  /// [JOSE crv](https://www.iana.org/assignments/jose/jose.xhtml)
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

  Jwk bytesToPublicKey(Uint8List input);
}
