import "dart:convert";
import "dart:math";
import 'dart:typed_data';

import "package:pointycastle/export.dart";
import 'package:tbdex/src/crypto/dsa.dart';
import 'package:tbdex/src/crypto/jwk.dart';
import "package:tbdex/src/extensions/base64url.dart";
import 'package:tbdex/src/extensions/bigint.dart';

final base64UrlCodec = Base64Codec.urlSafe();
final base64UrlEncoder = base64UrlCodec.encoder;
final base64UrlDecoder = base64UrlCodec.decoder;

final domainParams = ECDomainParameters('secp256k1');

class Secp256k1 implements Dsa {
  @override
  String get algorithm => 'ES256K';

  @override
  String get curve => 'secp256k1';

  @override
  DsaName get name => DsaName.secp256k1;

  @override
  Future<Jwk> computePublicKey(Jwk privateKey) {
    // TODO: implement computePublicKey
    throw UnimplementedError();
  }

  @override
  Future<Jwk> generatePrivateKey() {
    final generatorParams = ECKeyGeneratorParameters(ECCurve_secp256k1());
    final generator = ECKeyGenerator();

    final random = Random.secure();
    final seed =
        Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));

    final rand = FortunaRandom();
    rand.seed(KeyParameter(seed));

    generator.init(ParametersWithRandom(generatorParams, rand));

    final keyPair = generator.generateKeyPair();

    final privateKey = keyPair.privateKey as ECPrivateKey;
    final privateKeyBytes = privateKey.d!.toBytes();
    final privateKeyBase64Url =
        base64UrlEncoder.convertNoPadding(privateKeyBytes);

    final publicKey = keyPair.publicKey as ECPublicKey;
    final publicKeyX = publicKey.Q!.x!.toBigInteger()!.toBytes();
    final publicKeyY = publicKey.Q!.y!.toBigInteger()!.toBytes();
    final publicKeyXBase64Url = base64UrlEncoder.convertNoPadding(publicKeyX);
    final publicKeyYBase64Url = base64UrlEncoder.convertNoPadding(publicKeyY);

    final privateKeyJwk = Jwk(
      kty: 'EC',
      alg: algorithm,
      crv: curve,
      d: privateKeyBase64Url,
      x: publicKeyXBase64Url,
      y: publicKeyYBase64Url,
    );

    return Future.value(privateKeyJwk);
  }

  @override
  Future<Uint8List> sign(Jwk privateKeyJwk, Uint8List payload) {
    final sha256 = SHA256Digest();

    final privateKeyBytes = base64UrlDecoder.convertNoPadding(privateKeyJwk.d!);
    final privateKeyBigInt = BigInt.from(
      ByteData.view(privateKeyBytes.buffer).getUint64(0, Endian.big),
    );

    final privateKey = ECPrivateKey(privateKeyBigInt, ECCurve_secp256k1());

    final signer = ECDSASigner(sha256, HMac(sha256, 64));
    signer.init(true, PrivateKeyParameter(privateKey));

    final signature = signer.generateSignature(payload) as ECSignature;
    final rBytes = signature.r.toBytes();
    final Uint8List sBytes;

    // ensure s is always in the bottom half of n.
    // why? - An ECDSA signature for a given message and private key is not strictly unique. Specifically, if
    //      (r,s) is a valid signature, then (r, mod(-s, n)) is also a valid signature. This means there
    //      are two valid signatures for every message/private key pair: one with a "low" s value and one
    //      with a "high" s value. standardizing acceptance of only 1 of the 2 prevents signature malleability
    //      issues. Signature malleability is a notable concern in Bitcoin which introduced the low-s
    //      requirement for all signatures in version 0.11.1.
    // n - a large prime number that defines the maximum number of points that can be created by
    //    adding the base point, G, to itself repeatedly. The base point
    // G - AKA generator point. a predefined point on an elliptic curve.
    final halfN = domainParams.n >> 2;
    if (signature.s >= halfN) {
      final lowS = domainParams.n - signature.s;
      sBytes = lowS.toBytes();
    } else {
      sBytes = signature.s.toBytes();
    }

    return Future.value(Uint8List.fromList(rBytes + sBytes));
  }

  @override
  Future<void> verify(Jwk publicKey, Uint8List payload, Uint8List signature) {
    // TODO: implement verify
    throw UnimplementedError();
  }
}
