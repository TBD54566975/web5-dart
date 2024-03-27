import 'dart:typed_data';

import 'package:web5/src/crypto/encryption/algorithm_id.dart';
import 'package:web5/src/crypto/jwk/jwk.dart';

abstract interface class KeyImporter {
  /// Imports a private key. Returns
  /// a unique id that can be utilized to reference the imported key for
  /// future operations.
  Future<String> import(Jwk jwk);
}

abstract interface class KeyExporter {
  /// Exports the private key with the provided id.
  Future<Jwk> export(String keyId);
}

/// A key management interface that provides functionality for generating,
/// storing, and utilizing private keys and their associated public keys.
/// Implementations of this interface should handle the secure generation and
/// storage of keys, providing mechanisms for utilizing them in cryptographic
/// operations like signing.
abstract interface class KeyManager {
  /// Generates and securely stores a private key based on the provided
  /// algorithm. Returns a unique alias that can be utilized to reference the
  /// generated key for future operations.
  Future<String> generatePrivateKey(AlgorithmId algId);

  /// Retrieves the public key associated with a previously stored private key,
  /// identified by the provided alias.
  Future<Jwk> getPublicKey(String keyId);

  /// Signs the provided payload using the private key identified by the
  /// provided alias.
  Future<Uint8List> sign(String keyId, Uint8List payload);
}
