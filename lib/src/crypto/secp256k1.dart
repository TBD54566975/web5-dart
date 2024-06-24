import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:web5/src/encoders/base64url.dart';
import 'package:web5/src/crypto/jwk.dart';
import 'package:web5/src/extensions.dart';

final _curveParams = ECCurve_secp256k1();
final _keyGenParams = ECKeyGeneratorParameters(ECCurve_secp256k1());

class Secp256k1 {
  /// [JOSE kty](https://www.iana.org/assignments/jose/jose.xhtml)
  static const String kty = 'EC';

  /// [JOSE alg](https://www.iana.org/assignments/jose/jose.xhtml)
  static const String alg = 'ES256K';

  /// [JOSE crv](https://www.iana.org/assignments/jose/jose.xhtml)
  static const String crv = 'secp256k1';

  static Future<Jwk> computePublicKey(Jwk privateKey) {
    final privateKeyBytes = Base64Url.decode(privateKey.d!);
    final d = bytesToBigInt(privateKeyBytes).toUnsigned(256);

    final Q = (_curveParams.G * d)!;
    final x = Q.x!.toBigInteger();
    final y = Q.y!.toBigInteger();

    if (x == null || y == null) {
      throw Exception('Failed to generate public key from private key');
    }

    final publicKeyJwk = Jwk(
      kty: 'EC',
      alg: alg,
      crv: crv,
      x: Base64Url.encode(x.toBytes()),
      y: Base64Url.encode(y.toBytes()),
    );

    return Future.value(publicKeyJwk);
  }

  static Future<Jwk> generatePrivateKey() {
    final keyGenerator = ECKeyGenerator();

    final seedGen = Random.secure();
    final seed =
        Uint8List.fromList(List.generate(32, (_) => seedGen.nextInt(256)));

    final rand = FortunaRandom();
    rand.seed(KeyParameter(seed));

    keyGenerator.init(ParametersWithRandom(_keyGenParams, rand));
    final keyPair = keyGenerator.generateKeyPair();

    final privateKey = keyPair.privateKey as ECPrivateKey;
    final d = privateKey.d!.toUnsigned(256);

    final publicKey = keyPair.publicKey as ECPublicKey;
    final Q = publicKey.Q!;
    final x = Q.x!.toBigInteger()!.toUnsigned(256);
    final y = Q.y!.toBigInteger()!.toUnsigned(256);

    final privateKeyBase64Url = Base64Url.encode(d.toBytes());
    final publicKeyXBase64Url = Base64Url.encode(x.toBytes());
    final publicKeyYBase64Url = Base64Url.encode(y.toBytes());

    final privateKeyJwk = Jwk(
      kty: 'EC',
      alg: alg,
      crv: crv,
      d: privateKeyBase64Url,
      x: publicKeyXBase64Url,
      y: publicKeyYBase64Url,
    );

    return Future.value(privateKeyJwk);
  }

  static Uint8List publicKeyToBytes({required Jwk publicKey}) {
    if (publicKey.x == null) {
      throw Error();
    }

    final Uint8List encodedKey = utf8.encode(publicKey.x!);
    final String base64Url = base64UrlEncode(encodedKey);

    return utf8.encode(base64Url);
  }

  static Future<Uint8List> sign(Jwk privateKeyJwk, Uint8List payload) {
    final sha256 = SHA256Digest();

    final privateKeyBytes = Base64Url.decode(privateKeyJwk.d!);
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
    final halfN = _curveParams.n >> 2;
    if (signature.s >= halfN) {
      final lowS = _curveParams.n - signature.s;
      sBytes = lowS.toBytes();
    } else {
      sBytes = signature.s.toBytes();
    }

    return Future.value(Uint8List.fromList(rBytes + sBytes));
  }

  static Future<void> verify(
    Jwk publicKeyJwk,
    Uint8List payload,
    Uint8List signature,
  ) {
    final xBytes = Base64Url.decode(publicKeyJwk.x!);
    final x = bytesToBigInt(xBytes);

    final yBytes = Base64Url.decode(publicKeyJwk.y!);
    final y = bytesToBigInt(yBytes);

    final Q = _curveParams.curve.createPoint(x, y);
    final publicKey = ECPublicKey(Q, _curveParams);

    final sha256 = SHA256Digest();
    final verifier = ECDSASigner(sha256, HMac(sha256, 64));
    verifier.init(false, PublicKeyParameter(publicKey));

    final r = bytesToBigInt(signature.sublist(0, 32));
    final s = bytesToBigInt(signature.sublist(32));

    final ecSignature = ECSignature(r, s);
    final isLegit = verifier.verifySignature(payload, ecSignature);

    if (!isLegit) {
      throw Exception('Integrity check failed');
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

  static Jwk bytesToPublicKey(Uint8List input) {
    final xBytes = input.sublist(1, 33);
    final yBytes = input.sublist(33, 65);

    return Jwk(
      kty: kty,
      alg: alg,
      crv: crv,
      x: Base64Url.encode(xBytes),
      y: Base64Url.encode(yBytes),
    );
  }
}
