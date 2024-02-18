import 'dart:convert';

import 'package:web5/src/crypto.dart';
import 'package:web5/src/dids/did.dart';
import 'package:web5/src/extensions.dart';
import 'package:web5/src/dids/did_core.dart';
import 'package:web5/src/dids/bearer_did.dart';
import 'package:web5/src/dids/did_method_resolver.dart';

/// Class that can be used to create and resolve `did:jwk` DIDs.
/// `did:jwk` is useful in scenarios where:
/// * Offline resolution is preferred
/// * Key rotation is not required
/// * [Service](https://www.w3.org/TR/did-core/#services) endpoints are not necessary
///
/// [Specification](https://github.com/quartzjer/did-jwk/blob/main/spec.md)
class DidJwk {
  static const String methodName = 'jwk';

  static final resolver = DidMethodResolver(name: methodName, resolve: resolve);

  /// Creates a new `did:jwk`. Stores associated private key in provided
  /// key manager.
  static Future<BearerDid> create({
    AlgorithmId? algorithmId,
    KeyManager? keyManager,
  }) async {
    algorithmId ??= AlgorithmId.ed25519;
    keyManager ??= InMemoryKeyManager();

    final keyAlias = await keyManager.generatePrivateKey(algorithmId);

    final publicKeyJwk = await keyManager.getPublicKey(keyAlias);
    final publicKeyJwkBase64Url = json.toBase64Url(publicKeyJwk);

    final uri = 'did:jwk:$publicKeyJwkBase64Url';
    final did = Did.parse(uri);

    return BearerDid(
      uri: uri,
      keyManager: keyManager,
      document: _createDidDocument(did, publicKeyJwk),
    );
  }

  /// Resolves a `did:jwk` URI into a [DidResolutionResult].
  ///
  /// This method parses the provided `didUri` to extract the JWK information.
  /// It validates the method of the DID URI and then attempts to parse the
  /// JWK from the URI. If successful, it constructs a [DidDocument] with the
  /// resolved JWK, generating a [DidResolutionResult].
  ///
  /// The method ensures that the DID URI adheres to the `did:jwk` method
  /// specification and handles exceptions that may arise during the parsing
  /// and resolution process.
  ///
  /// Returns a [DidResolutionResult] containing the resolved DID document.
  /// If the DID URI is invalid, not conforming to the `did:jwk` method, or
  /// if any other error occurs during the resolution process, it returns
  /// an invalid [DidResolutionResult].
  ///
  /// Throws [FormatException] if the JWK parsing fails.
  static Future<DidResolutionResult> resolve(Did did) {
    if (did.method != methodName) {
      return Future.value(DidResolutionResult.invalidDid());
    }

    final dynamic jwk;

    try {
      jwk = json.fromBase64Url(did.id);
    } on FormatException {
      return Future.value(DidResolutionResult.invalidDid());
    }

    final Jwk parsedJwk;

    try {
      parsedJwk = Jwk.fromJson(jwk);
    } on Exception {
      return Future.value(DidResolutionResult.invalidDid());
    }

    final didDocument = _createDidDocument(did, parsedJwk);
    final didResolutionResult = DidResolutionResult(didDocument: didDocument);

    return Future.value(didResolutionResult);
  }

  static DidDocument _createDidDocument(Did did, Jwk jwk) {
    final verificationMethod = DidVerificationMethod(
      id: '${did.id}#0',
      type: 'JsonWebKey2020',
      controller: did.id,
      publicKeyJwk: jwk,
    );

    return DidDocument(
      id: did.id,
      verificationMethod: [verificationMethod],
      assertionMethod: [verificationMethod.id],
      authentication: [verificationMethod.id],
      capabilityInvocation: [verificationMethod.id],
      capabilityDelegation: [verificationMethod.id],
    );
  }
}
