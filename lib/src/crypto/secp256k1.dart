import "dart:convert";
import "dart:math";
import 'dart:typed_data';

import "package:pointycastle/export.dart";
import 'package:tbdex/src/crypto/dsa.dart';
import 'package:tbdex/src/crypto/jwk.dart';
import "package:tbdex/src/extensions/base64url.dart";
import 'package:tbdex/src/extensions/bigint.dart';

final _base64UrlCodec = Base64Codec.urlSafe();
final _base64UrlEncoder = _base64UrlCodec.encoder;
final _base64UrlDecoder = _base64UrlCodec.decoder;

final curveParams = ECCurve_secp256k1();
final keyGenParams = ECKeyGeneratorParameters(ECCurve_secp256k1());

class Secp256k1 implements Dsa {
  /// [JOSE kty](https://www.iana.org/assignments/jose/jose.xhtml)
  static final String kty = 'EC';

  /// [JOSE alg](https://www.iana.org/assignments/jose/jose.xhtml)
  static final String alg = 'ES256K';

  /// [JOSE crv](https://www.iana.org/assignments/jose/jose.xhtml)
  static final String crv = 'secp256k1';

  @override
  final String keyType = kty;

  @override
  final String algorithm = alg;

  @override
  final String curve = crv;

  @override
  DsaName name = DsaName.secp256k1;

  @override
  Future<Jwk> computePublicKey(Jwk privateKey) {
    final privateKeyBytes = _base64UrlDecoder.convertNoPadding(privateKey.d!);
    final d = bytesToBigInt(privateKeyBytes).toUnsigned(256);

    final Q = (curveParams.G * d)!;
    final x = Q.x!.toBigInteger();
    final y = Q.y!.toBigInteger();

    if (x == null || y == null) {
      throw Exception("Failed to generate public key from private key");
    }

    final publicKeyJwk = Jwk(
      kty: 'EC',
      alg: algorithm,
      crv: curve,
      x: _base64UrlEncoder.convertNoPadding(x.toBytes()),
      y: _base64UrlEncoder.convertNoPadding(y.toBytes()),
    );

    return Future.value(publicKeyJwk);
  }

  @override
  Future<Jwk> generatePrivateKey() {
    final keyGenerator = ECKeyGenerator();

    final seedGen = Random.secure();
    final seed =
        Uint8List.fromList(List.generate(32, (_) => seedGen.nextInt(256)));

    final rand = FortunaRandom();
    rand.seed(KeyParameter(seed));

    keyGenerator.init(ParametersWithRandom(keyGenParams, rand));
    final keyPair = keyGenerator.generateKeyPair();

    final privateKey = keyPair.privateKey as ECPrivateKey;
    final d = privateKey.d!.toUnsigned(256);

    final publicKey = keyPair.publicKey as ECPublicKey;
    final Q = publicKey.Q!;
    final x = Q.x!.toBigInteger()!.toUnsigned(256);
    final y = Q.y!.toBigInteger()!.toUnsigned(256);

    final privateKeyBase64Url = _base64UrlEncoder.convertNoPadding(d.toBytes());
    final publicKeyXBase64Url = _base64UrlEncoder.convertNoPadding(x.toBytes());
    final publicKeyYBase64Url = _base64UrlEncoder.convertNoPadding(y.toBytes());

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

    final privateKeyBytes =
        _base64UrlDecoder.convertNoPadding(privateKeyJwk.d!);
    final privateKeyBigInt = bytesToBigInt(privateKeyBytes);
    final privateKey = ECPrivateKey(privateKeyBigInt, ECCurve_secp256k1());

    final signer = ECDSASigner(sha256, HMac(sha256, 64));
    signer.init(true, PrivateKeyParameter(privateKey));

    final signature = signer.generateSignature(payload) as ECSignature;
    final rBytes = signature.r.toBytes();
    final Uint8List sBytes;

    // ensure s is always in the bottom half of n.
    // why? - An ECDSA signature for a given message and private key is not
    // strictly unique. Specifically, if (r,s) is a valid signature, then
    // (r, mod(-s, n)) is also a valid signature. This means there are two valid
    // signatures for every message/private key pair: one with a "low" s value
    // and one with a "high" s value. standardizing acceptance of only 1 of the
    // 2 prevents signature malleability issues. Signature malleability is a
    // notable concern in Bitcoin which introduced the low-s requirement for all
    // signatures in version 0.11.1.
    //
    // n - a large prime number that defines the maximum number of points that
    //can be created by adding the base point, G, to itself repeatedly.
    // G - AKA generator point is a
    // predefined point on an elliptic curve.
    final halfN = curveParams.n >> 2;
    if (signature.s >= halfN) {
      final lowS = curveParams.n - signature.s;
      sBytes = lowS.toBytes();
    } else {
      sBytes = signature.s.toBytes();
    }

    return Future.value(Uint8List.fromList(rBytes + sBytes));
  }

  @override
  Future<void> verify(
    Jwk publicKeyJwk,
    Uint8List payload,
    Uint8List signature,
  ) {
    final xBytes = _base64UrlDecoder.convertNoPadding(publicKeyJwk.x!);
    final x = bytesToBigInt(xBytes);

    final yBytes = _base64UrlDecoder.convertNoPadding(publicKeyJwk.y!);
    final y = bytesToBigInt(yBytes);

    final Q = curveParams.curve.createPoint(x, y);
    final publicKey = ECPublicKey(Q, curveParams);

    final sha256 = SHA256Digest();
    final verifier = ECDSASigner(sha256, HMac(sha256, 64));
    verifier.init(false, PublicKeyParameter(publicKey));

    final r = bytesToBigInt(signature.sublist(0, 32));
    final s = bytesToBigInt(signature.sublist(32));

    final ecSignature = ECSignature(r, s);
    final isLegit = verifier.verifySignature(payload, ecSignature);

    if (!isLegit) {
      throw Exception("Integrity check failed");
    }

    return Future.value();
  }

  static BigInt bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.from(0);

    for (int i = 0; i < bytes.length; i++) {
      result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
    }

    return result;
  }

  @override
  Jwk bytesToPublicKey(Uint8List input) {
    // TODO: implement bytesToPublicKey
    throw UnimplementedError();
  }
}
