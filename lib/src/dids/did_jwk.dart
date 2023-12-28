import 'dart:convert';

import 'package:tbdex/src/crypto/dsa.dart';

import './did.dart';
import '../extensions/json.dart';
import '../crypto/key_manager.dart';

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
  String uri;

  @override
  KeyManager keyManager;

  static String methodName = 'jwk';

  DidJwk({required this.uri, required this.keyManager});

  /// Creates a new `did:jwk`. Stores associated private key in provided
  /// key manager.
  static Future<DidJwk> create({required KeyManager keyManager}) async {
    final keyAlias = await keyManager.generatePrivateKey(DsaName.ed25519);

    final publicKeyJwk = await keyManager.getPublicKey(keyAlias);
    final publicKeyJwkBase64Url = json.toBase64Url(publicKeyJwk);

    return DidJwk(
        uri: "did:jwk:$publicKeyJwkBase64Url", keyManager: keyManager);
  }
}
