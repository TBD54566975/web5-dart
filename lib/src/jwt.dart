import 'dart:convert';
import 'dart:typed_data';

import 'package:tbdex/src/crypto/dsa.dart';
import 'package:tbdex/src/crypto/ed25519.dart';
import 'package:tbdex/src/crypto/secp256k1.dart';
import 'package:tbdex/src/dids/did.dart';
import 'package:tbdex/src/dids/did_resolver.dart';
import 'package:tbdex/src/extensions/base64url.dart';
import 'package:tbdex/src/extensions/json.dart';
import 'package:tbdex/tbdex.dart';

final base64UrlCodec = Base64Codec.urlSafe();
final base64UrlEncoder = base64UrlCodec.encoder;

/// A utility class for handling
/// [JSON Web Tokens (JWTs)](https://datatracker.ietf.org/doc/html/rfc7519)
///
/// This class provides functionalities to parse, encode, and sign JWTs.
/// It supports JWT signing with DID keys.
class Jwt {
  JwtEncoded encoded;
  JwtDecoded decoded;

  static final didResolver = DidResolver(methodResolvers: [DidJwk.resolver]);
  static final signers = {
    DsaName.ed25519: Ed25519(),
    DsaName.secp256k1: Secp256k1,
  };

  Jwt({required this.encoded, required this.decoded});

  /// Parses a signed JWT string into its decoded form. returns both split
  /// encoded and decoded forms
  ///
  /// Throws [Exception] if the JWT is malformed or if it does not meet
  /// the expected structure and encoding requirements.
  factory Jwt.parse(String signedJwt) {
    final splitJwt = signedJwt.split('.');

    if (splitJwt.length != 3) {
      throw Exception(
        'Malformed JWT. expected 3 parts. got ${splitJwt.length}',
      );
    }

    final [
      base64UrlEncodedHeader,
      base64UrlEncodedPayload,
      base64UrlEncodedSignature
    ] = splitJwt;

    final JwtHeader jwtHeader;

    try {
      jwtHeader = JwtHeader.fromBase64Url(base64UrlEncodedHeader);
    } on Exception {
      throw Exception(
        'Malformed JWT. Invalid base64url encoding for JWT header',
      );
    }

    if (jwtHeader.typ == null || jwtHeader.typ != 'JWT') {
      throw Exception('Expected JWT header to contain typ property set to JWT');
    }

    if (jwtHeader.alg == null || jwtHeader.kid == null) {
      throw Exception('Expected JWT header to contain alg and kid');
    }

    final JwtPayload jwtPayload;

    try {
      jwtPayload = JwtPayload.fromBase64Url(base64UrlEncodedPayload);
    } on Exception {
      throw Exception(
        'Malformed JWT. Invalid base64url encoding for JWT payload',
      );
    }

    return Jwt(
      decoded: JwtDecoded(header: jwtHeader, payload: jwtPayload),
      encoded: JwtEncoded(
        header: base64UrlEncodedHeader,
        payload: base64UrlEncodedPayload,
        signature: base64UrlEncodedSignature,
      ),
    );
  }

  /// Signs a JWT payload using a specified [Did] and returns the signed JWT.
  ///
  /// Throws [Exception] if any error occurs during the signing process.
  static Future<String> sign({
    required Did did,
    required JwtPayload jwtPayload,
  }) async {
    final resolutionResult = didResolver.resolve(did.uri);
    if (resolutionResult.hasError()) {
      throw Exception("failed to resolve DID");
    }

    final verificationMethod =
        resolutionResult.didDocument!.verificationMethod!.first;

    final String kid;
    if (verificationMethod.id.startsWith('#')) {
      kid = "${did.uri}${verificationMethod.id}";
    } else {
      kid = verificationMethod.id;
    }

    final publicKeyJwk = verificationMethod.publicKeyJwk!;
    final dsaName = DsaName.findByAlias(
        DsaAlias(algorithm: publicKeyJwk.alg, curve: publicKeyJwk.crv));

    final signer = signers[dsaName];
    if (signer == null) {
      throw Exception("$dsaName signing not supported");
    }

    final jwtHeader = JwtHeader(typ: 'JWT', kid: kid, alg: signer.algorithm);
    final jwtHeaderBase64Url = jwtHeader.toBase64Url();
    final jwtPayloadBase64Url = jwtPayload.toBase64Url();

    final toSign = "$jwtHeaderBase64Url.$jwtPayloadBase64Url";
    final toSignBytes = Uint8List.fromList(utf8.encode(toSign));

    final keyAlias = publicKeyJwk.computeThumbprint();

    final signatureBytes = await did.keyManager.sign(keyAlias, toSignBytes);
    final signatureBase64Url =
        base64UrlEncoder.convertNoPadding(signatureBytes);

    return "$jwtHeaderBase64Url.$jwtPayloadBase64Url.$signatureBase64Url";
  }
}

/// Represents the header portion of a JWT.
///
/// The header typically includes the type of token (JWT) and the
/// signing algorithm used.
class JwtHeader {
  String? typ;
  String? alg;
  String? kid;

  JwtHeader({this.typ, this.alg, this.kid});

  Map<String, dynamic> toJson() {
    return {
      if (typ != null) 'typ': typ,
      if (alg != null) 'alg': alg,
      if (kid != null) 'kid': kid,
    };
  }

  factory JwtHeader.fromBase64Url(String base64UrlEncodedHeader) {
    final jsonHeader = json.fromBase64Url(base64UrlEncodedHeader);

    return JwtHeader.fromJson(jsonHeader);
  }

  factory JwtHeader.fromJson(Map<String, dynamic> json) {
    return JwtHeader(
      typ: json['typ'] as String?,
      alg: json['alg'] as String?,
      kid: json['kid'] as String?,
    );
  }

  String toBase64Url() {
    final jsonHeader = toJson();
    return json.toBase64Url(jsonHeader);
  }
}

/// Represents the payload of a JWT.
///
/// This class contains the claims of the JWT, such as issuer, subject,
/// audience, expiration time, etc.
class JwtPayload {
  String? iss;
  String? sub;
  dynamic _aud;
  int? exp;
  int? nbf;
  int? iat;
  String? jti;

  JwtPayload(
      {this.iss, this.sub, dynamic aud, this.exp, this.nbf, this.iat, this.jti})
      : _aud = aud;

  /// Sets the audience claim.
  ///
  /// The value can be either a single string or a list of strings.
  /// Throws [ArgumentError] if the value is not a string or list of strings.
  set aud(dynamic value) {
    if (value is String || value is List<String>) {
      _aud = value;
    } else {
      throw ArgumentError('aud must be either String or List<String>');
    }
  }

  dynamic get aud => _aud;

  Map<String, dynamic> toJson() {
    return {
      if (iss != null) 'iss': iss,
      if (sub != null) 'sub': sub,
      if (_aud != null) 'aud': _aud,
      if (exp != null) 'exp': exp,
      if (nbf != null) 'nbf': nbf,
      if (iat != null) 'iat': iat,
      if (jti != null) 'jti': jti,
    };
  }

  factory JwtPayload.fromJson(Map<String, dynamic> json) {
    return JwtPayload(
      iss: json['iss'] as String?,
      sub: json['sub'] as String?,
      aud: json['aud'],
      exp: json['exp'] as int?,
      nbf: json['nbf'] as int?,
      iat: json['iat'] as int?,
      jti: json['jti'] as String?,
    );
  }

  factory JwtPayload.fromBase64Url(String base64UrlEncodedPayload) {
    final jsonPayload = json.fromBase64Url(base64UrlEncodedPayload);

    return JwtPayload.fromJson(jsonPayload);
  }

  String toBase64Url() {
    final jsonPayload = toJson();
    return json.toBase64Url(jsonPayload);
  }
}

/// Represents a decoded JWT, including both its header and payload.
///
/// **Note**: Signature not included because its decoded form would be bytes
class JwtDecoded {
  final JwtHeader header;
  final JwtPayload payload;

  JwtDecoded({required this.header, required this.payload});

  factory JwtDecoded.fromJson(Map<String, dynamic> json) {
    return JwtDecoded(
      header: JwtHeader.fromJson(json['header']),
      payload: JwtPayload.fromJson(json['payload']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'header': header.toJson(),
      'payload': payload.toJson(),
    };
  }
}

/// Represents an encoded JWT, including its encoded header, payload,
/// and signature.

class JwtEncoded {
  final String? header;
  final String? payload;
  final String? signature;

  JwtEncoded({required this.header, required this.payload, this.signature});

  factory JwtEncoded.fromJson(Map<String, dynamic> json) {
    return JwtEncoded(
      header: json['header'],
      payload: json['payload'],
      signature: json['signature'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'header': header,
      'payload': payload,
      'signature': signature,
    };
  }
}
