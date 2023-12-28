import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as crypto;

import '../extensions/base64url.dart';
import './dsa.dart';
import './jwk.dart';

final ed25519 = crypto.Ed25519();
final base64UrlCodec = Base64Codec.urlSafe();
final base64UrlEncoder = base64UrlCodec.encoder;
final base64UrlDecoder = base64UrlCodec.decoder;

class Ed25519 implements Dsa {
  @override
  DsaName name = DsaName.ed25519;

  @override
  String algorithm = 'EdDSA';

  @override
  String curve = 'Ed25519';

  @override
  Future<Jwk> computePublicKey(Jwk privateKey) async {
    var privateKeyBytes = base64UrlDecoder.convertNoPadding(privateKey.d!);

    var keyPair = await ed25519.newKeyPairFromSeed(privateKeyBytes);
    var publicKey = await keyPair.extractPublicKey();
    var publicKeyJwk = Jwk(
        kty: 'OKP',
        alg: 'EdDSA',
        crv: 'Ed25519',
        x: base64UrlEncoder.convertNoPadding(publicKey.bytes));

    return publicKeyJwk;
  }

  @override
  Future<Jwk> generatePrivateKey() async {
    var keyPair = await ed25519.newKeyPair();

    var privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    var privateKeyJwk = Jwk(
      kty: 'OKP',
      alg: 'EdDSA',
      crv: 'Ed25519',
      d: base64UrlEncoder.convertNoPadding(privateKeyBytes),
    );

    return privateKeyJwk;
  }

  @override
  Future<Uint8List> sign(Jwk privateKey, Uint8List payload) async {
    var privateKeyBytes = base64UrlDecoder.convert(privateKey.d!);

    var keyPair = await ed25519.newKeyPairFromSeed(privateKeyBytes);
    var signature = await ed25519.sign(payload, keyPair: keyPair);

    return Uint8List.fromList(signature.bytes);
  }

  @override
  Future<void> verify(
      Jwk publicKeyJwk, Uint8List payload, Uint8List signatureBytes) async {
    var publicKeyBytes = base64UrlDecoder.convert(publicKeyJwk.x!);
    var publicKey = crypto.SimplePublicKey(publicKeyBytes,
        type: crypto.KeyPairType.ed25519);

    var signature = crypto.Signature(signatureBytes, publicKey: publicKey);
    var isLegit = await ed25519.verify(payload, signature: signature);

    if (isLegit == false) {
      throw Exception("Integrity check failed");
    }
  }
}
