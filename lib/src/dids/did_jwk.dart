import 'dart:convert';

import 'package:tbdex/src/crypto/dsa.dart';

import 'package:tbdex/src/dids/did.dart';
import 'package:tbdex/src/crypto/jwk.dart';
import 'package:tbdex/src/extensions/json.dart';
import 'package:tbdex/src/crypto/key_manager.dart';

final base64UrlEncoder = Base64Codec.urlSafe().encoder;

/// Class that can be used to create and resolve `did:jwk` DIDs.
/// `did:jwk` is useful in scenarios where:
/// * Offline resolution is preferred
/// * Key rotation is not required
/// * [Service](https://www.w3.org/TR/did-core/#services) endpoints are not necessary
///
/// [Specification](https://github.com/quartzjer/did-jwk/blob/main/spec.md)
class DidJwk implements Did {
  @override
  final String uri;

  @override
  final KeyManager keyManager;

  static String methodName = 'jwk';

  DidJwk({required this.uri, required this.keyManager});

  /// Creates a new `did:jwk`. Stores associated private key in provided
  /// key manager.
  static Future<DidJwk> create({required KeyManager keyManager}) async {
    final keyAlias = await keyManager.generatePrivateKey(DsaName.ed25519);

    final publicKeyJwk = await keyManager.getPublicKey(keyAlias);
    final publicKeyJwkBase64Url = json.toBase64Url(publicKeyJwk);

    return DidJwk(
      uri: "did:jwk:$publicKeyJwkBase64Url",
      keyManager: keyManager,
    );
  }

  static DidResolutionResult resolve(String didUri) {
    final parsedDidUri = DidUri.parse(didUri);

    if (parsedDidUri.method != 'jwk') {
      throw Exception("Invalid DID Method");
    }

    final jwk = json.fromBase64Url(parsedDidUri.id);
    final verificationMethod = VerificationMethod(
      id: "$didUri#0",
      type: "JsonWebKey2020",
      controller: didUri,
      publicKeyJwk: Jwk.fromJson(jwk),
    );

    final didDocument = DidDocument(
      id: didUri,
      verificationMethod: [
        verificationMethod,
      ],
      assertionMethod: [
        verificationMethod.id,
      ],
      authentication: [
        verificationMethod.id,
      ],
      capabilityInvocation: [
        verificationMethod.id,
      ],
      capabilityDelegation: [
        verificationMethod.id,
      ],
    );

    final didResolutionResult = DidResolutionResult(didDocument: didDocument);

    return didResolutionResult;
  }
}
