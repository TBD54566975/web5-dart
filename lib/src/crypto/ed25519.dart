import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as crypto;

import 'package:tbdex/src/extensions/base64url.dart';
import 'package:tbdex/src/crypto/dsa.dart';
import 'package:tbdex/src/crypto/jwk.dart';

final ed25519 = crypto.Ed25519();
final base64UrlCodec = Base64Codec.urlSafe();
final base64UrlEncoder = base64UrlCodec.encoder;
final base64UrlDecoder = base64UrlCodec.decoder;

/// Implements the Ed25519 Digital Signature Algorithm (DSA) for cryptographic
/// operations.
///
/// `Ed25519` is an instance of the [Dsa] interface, providing methods to generate
/// private keys, compute public keys, sign data, and verify signatures.
class Ed25519 implements Dsa {
  /// [JOSE registered](https://datatracker.ietf.org/doc/html/draft-ietf-jose-cfrg-curves-06#section-2)
  /// key type
  static final String kty = 'OKP';

  /// [JOSE registered](https://datatracker.ietf.org/doc/html/draft-ietf-jose-cfrg-curves-06#section-3)
  /// algorithm
  static final String alg = 'EdDSA';

  /// [JOSE registered](https://datatracker.ietf.org/doc/html/draft-ietf-jose-cfrg-curves-06#section-3)
  /// curve
  static final String crv = 'Ed25519';

  /// [JOSE registered](https://datatracker.ietf.org/doc/html/draft-ietf-jose-cfrg-curves-06#section-2)
  /// key type
  @override
  final String keyType = kty;

  /// [JOSE registered](https://datatracker.ietf.org/doc/html/draft-ietf-jose-cfrg-curves-06#section-3)
  /// algorithm
  @override
  final String algorithm = alg;

  /// [JOSE registered](https://datatracker.ietf.org/doc/html/draft-ietf-jose-cfrg-curves-06#section-3)
  /// curve
  @override
  final String curve = crv;

  @override
  final DsaName name = DsaName.ed25519;

  @override
  Future<Jwk> computePublicKey(Jwk privateKey) async {
    final privateKeyBytes = base64UrlDecoder.convertNoPadding(privateKey.d!);

    final keyPair = await ed25519.newKeyPairFromSeed(privateKeyBytes);
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyJwk = Jwk(
      kty: kty,
      alg: alg,
      crv: crv,
      x: base64UrlEncoder.convertNoPadding(publicKey.bytes),
    );

    return publicKeyJwk;
  }

  @override
  Future<Jwk> generatePrivateKey() async {
    final keyPair = await ed25519.newKeyPair();

    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final privateKeyJwk = Jwk(
      kty: kty,
      alg: alg,
      crv: crv,
      d: base64UrlEncoder.convertNoPadding(privateKeyBytes),
    );

    return privateKeyJwk;
  }

  @override
  Future<Uint8List> sign(Jwk privateKey, Uint8List payload) async {
    final privateKeyBytes = base64UrlDecoder.convertNoPadding(privateKey.d!);

    final keyPair = await ed25519.newKeyPairFromSeed(privateKeyBytes);
    final signature = await ed25519.sign(payload, keyPair: keyPair);

    return Uint8List.fromList(signature.bytes);
  }

  @override
  Future<void> verify(
    Jwk publicKeyJwk,
    Uint8List payload,
    Uint8List signatureBytes,
  ) async {
    final publicKeyBytes = base64UrlDecoder.convertNoPadding(publicKeyJwk.x!);
    final publicKey = crypto.SimplePublicKey(
      publicKeyBytes,
      type: crypto.KeyPairType.ed25519,
    );

    final signature = crypto.Signature(signatureBytes, publicKey: publicKey);
    final isLegit = await ed25519.verify(payload, signature: signature);

    if (isLegit == false) {
      throw Exception("Integrity check failed");
    }
  }

  @override
  Jwk bytesToPublicKey(Uint8List input) {
    return Jwk(
      kty: kty,
      alg: alg,
      crv: crv,
      x: base64UrlEncoder.convertNoPadding(input),
    );
  }
}
