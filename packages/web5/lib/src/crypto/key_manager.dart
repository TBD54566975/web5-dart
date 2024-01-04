import 'dart:typed_data';

import 'package:web5/src/crypto/jwk.dart';
import 'package:web5/src/crypto/dsa.dart';

/// A key management interface that provides functionality for generating,
/// storing, and utilizing private keys and their associated public keys.
/// Implementations of this interface should handle the secure generation and
/// storage of keys, providing mechanisms for utilizing them in cryptographic
/// operations like signing.
abstract interface class KeyManager {
  /// Generates and securely stores a private key based on the provided
  /// algorithm. Returns a unique alias that can be utilized to reference the
  /// generated key for future operations.
  Future<String> generatePrivateKey(DsaName alg);

  /// Retrieves the public key associated with a previously stored private key,
  /// identified by the provided alias.
  Future<Jwk> getPublicKey(String keyAlias);

  /// Signs the provided payload using the private key identified by the
  /// provided alias.
  Future<Uint8List> sign(String keyAlias, Uint8List payload);
}
