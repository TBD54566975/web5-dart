import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as crypto;
import 'package:web5/src/encoders/base64url.dart';

import 'package:web5/src/crypto/jwk.dart';

final ed25519 = crypto.Ed25519();

class Ed25519 {
  /// [JOSE registered](https://datatracker.ietf.org/doc/html/draft-ietf-jose-cfrg-curves-06#section-2)
  /// key type
  static const String kty = 'OKP';

  /// [JOSE registered](https://datatracker.ietf.org/doc/html/draft-ietf-jose-cfrg-curves-06#section-3)
  /// algorithm
  static const String alg = 'EdDSA';

  /// [JOSE registered](https://datatracker.ietf.org/doc/html/draft-ietf-jose-cfrg-curves-06#section-3)
  /// curve
  static const String crv = 'Ed25519';

  static Future<Jwk> computePublicKey(Jwk privateKey) async {
    final privateKeyBytes = Base64Url.decode(privateKey.d!);

    final keyPair = await ed25519.newKeyPairFromSeed(privateKeyBytes);
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyJwk = Jwk(
      kty: kty,
      alg: alg,
      crv: crv,
      x: Base64Url.encode(publicKey.bytes),
    );

    return publicKeyJwk;
  }

  static Future<Jwk> generatePrivateKey({Uint8List? seed}) async {
    crypto.SimpleKeyPair keyPair;

    if (seed == null) {
      keyPair = await ed25519.newKeyPair();
    } else {
      keyPair = await ed25519.newKeyPairFromSeed(seed);
    }

    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyJwk = Jwk(
      kty: kty,
      alg: alg,
      crv: crv,
      d: Base64Url.encode(privateKeyBytes),
      x: Base64Url.encode(publicKey.bytes),
    );

    return privateKeyJwk;
  }

  static Uint8List publicKeyToBytes({required Jwk publicKey}) {
    if (publicKey.x == null) {
      throw Error();
    }

    return Base64Url.decode(publicKey.x!);
  }

  static Future<Uint8List> sign(Jwk privateKey, Uint8List payload) async {
    final privateKeyBytes = Base64Url.decode(privateKey.d!);

    final keyPair = await ed25519.newKeyPairFromSeed(privateKeyBytes);
    final signature = await ed25519.sign(payload, keyPair: keyPair);

    return Uint8List.fromList(signature.bytes);
  }

  static Future<void> verify(
    Jwk publicKeyJwk,
    Uint8List payload,
    Uint8List signatureBytes,
  ) async {
    final publicKeyBytes = Base64Url.decode(publicKeyJwk.x!);
    final publicKey = crypto.SimplePublicKey(
      publicKeyBytes,
      type: crypto.KeyPairType.ed25519,
    );

    final signature = crypto.Signature(signatureBytes, publicKey: publicKey);
    final isLegit = await ed25519.verify(payload, signature: signature);

    if (isLegit == false) {
      throw Exception('Integrity check failed');
    }
  }

  static Jwk bytesToPublicKey(Uint8List input) {
    return Jwk(
      kty: kty,
      alg: alg,
      crv: crv,
      x: Base64Url.encode(input),
    );
  }
}
