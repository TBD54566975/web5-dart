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

class Ed25519 implements Dsa {
  @override
  final DsaName name = DsaName.ed25519;

  @override
  final String algorithm = 'EdDSA';

  @override
  final String curve = 'Ed25519';

  @override
  Future<Jwk> computePublicKey(Jwk privateKey) async {
    final privateKeyBytes = base64UrlDecoder.convertNoPadding(privateKey.d!);

    final keyPair = await ed25519.newKeyPairFromSeed(privateKeyBytes);
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyJwk = Jwk(
      kty: 'OKP',
      alg: 'EdDSA',
      crv: 'Ed25519',
      x: base64UrlEncoder.convertNoPadding(publicKey.bytes),
    );

    return publicKeyJwk;
  }

  @override
  Future<Jwk> generatePrivateKey() async {
    final keyPair = await ed25519.newKeyPair();

    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final privateKeyJwk = Jwk(
      kty: 'OKP',
      alg: 'EdDSA',
      crv: 'Ed25519',
      d: base64UrlEncoder.convertNoPadding(privateKeyBytes),
    );

    return privateKeyJwk;
  }

  @override
  Future<Uint8List> sign(Jwk privateKey, Uint8List payload) async {
    final privateKeyBytes = base64UrlDecoder.convert(privateKey.d!);

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
    final publicKeyBytes = base64UrlDecoder.convert(publicKeyJwk.x!);
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
}
