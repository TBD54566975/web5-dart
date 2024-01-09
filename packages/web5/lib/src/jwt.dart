import 'dart:convert';

import 'package:web5/src/extensions/json.dart';
import 'package:web5/src/jws.dart';
import 'package:web5/web5.dart';

/// A utility class for handling
/// [JSON Web Tokens (JWTs)](https://datatracker.ietf.org/doc/html/rfc7519)
///
/// This class provides functionalities to parse, encode, and sign JWTs.
/// It supports JWT signing with DID keys.
class Jwt {
  JwtEncoded encoded;
  JwtDecoded decoded;

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

    final JwtHeader header;

    try {
      header = JwtHeader.fromBase64Url(base64UrlEncodedHeader);
    } on Exception {
      throw Exception(
        'Malformed JWT. Invalid base64url encoding for JWT header',
      );
    }

    if (header.typ == null || header.typ != 'JWT') {
      throw Exception('Expected JWT header to contain typ property set to JWT');
    }

    if (header.alg == null || header.kid == null) {
      throw Exception('Expected JWT header to contain alg and kid');
    }

    final JwtClaims payload;

    try {
      payload = JwtClaims.fromBase64Url(base64UrlEncodedPayload);
    } on Exception {
      throw Exception(
        'Malformed JWT. Invalid base64url encoding for JWT payload',
      );
    }

    return Jwt(
      decoded: JwtDecoded(header: header, payload: payload),
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
    required JwtClaims payload,
  }) async {
    final header = JwtHeader(typ: 'JWT');
    final payloadBytes = json.toBytes(payload.toJson());

    return Jws.sign(did: did, payload: payloadBytes, header: header);
  }

  // static Future<void> verify(String signedJwt) {
  //   final parsedJwt = Jwt.parse(signedJwt);
  //   final header = parsedJwt.decoded.header;
  // }
}

/// JWT Headers are JWS Headers. type aliasing because this could cause confusion
/// for non-neckbeards
typedef JwtHeader = JwsHeader;

/// Represents JWT Claims
///
/// [Specification Reference](https://datatracker.ietf.org/doc/html/rfc7519#section-4)
class JwtClaims {
  /// The "iss" (issuer) claim identifies the principal that issued the
  /// JWT.
  ///
  /// [Specification Reference](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.1)
  String? iss;

  /// The "sub" (subject) claim identifies the principal that is the
  /// subject of the JWT.
  ///
  /// [Specification Reference](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.2)
  String? sub;

  /// The "aud" (audience) claim identifies the recipients that the JWT is
  /// intended for.
  ///
  /// [Specification Reference](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.3)
  dynamic _aud;

  /// The "exp" (expiration time) claim identifies the expiration time on
  /// or after which the JWT must not be accepted for processing.
  ///
  /// [Specification Reference](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.4)
  int? exp;

  /// The "nbf" (not before) claim identifies the time before which the JWT
  /// must not be accepted for processing.
  ///
  /// [Specification Reference](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.5)
  int? nbf;

  /// The "iat" (issued at) claim identifies the time at which the JWT was
  /// issued.
  ///
  /// [Specification Reference](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.6)
  int? iat;

  /// The "jti" (JWT ID) claim provides a unique identifier for the JWT.
  ///
  /// [Specification Reference](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.7)
  String? jti;

  JwtClaims({
    this.iss,
    this.sub,
    dynamic aud,
    this.exp,
    this.nbf,
    this.iat,
    this.jti,
  }) : _aud = aud;

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

  factory JwtClaims.fromJson(Map<String, dynamic> json) {
    return JwtClaims(
      iss: json['iss'] as String?,
      sub: json['sub'] as String?,
      aud: json['aud'],
      exp: json['exp'] as int?,
      nbf: json['nbf'] as int?,
      iat: json['iat'] as int?,
      jti: json['jti'] as String?,
    );
  }

  factory JwtClaims.fromBase64Url(String base64UrlEncodedPayload) {
    final jsonPayload = json.fromBase64Url(base64UrlEncodedPayload);

    return JwtClaims.fromJson(jsonPayload);
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
  final JwtClaims payload;

  JwtDecoded({required this.header, required this.payload});

  factory JwtDecoded.fromJson(Map<String, dynamic> json) {
    return JwtDecoded(
      header: JwtHeader.fromJson(json['header']),
      payload: JwtClaims.fromJson(json['payload']),
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
