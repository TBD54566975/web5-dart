import 'dart:convert';

import 'package:web5/src/jws/jws.dart';
import 'package:web5/src/dids/did.dart';
import 'package:web5/src/jwt/jwt_claims.dart';
import 'package:web5/src/extensions/json.dart';
import 'package:web5/src/jwt/jwt_decoded.dart';
import 'package:web5/src/jwt/jwt_encoded.dart';
import 'package:web5/src/jwt/jwt_header.dart';

/**
 * TODO: refactor. awkward implementation:
 *   * Jwt.parse() returns an instance of Jwt but you can't call sign on an
 *     an instance of Jwt. Likely makes most sense for Jwt to have static methods
 *     only and potentially return something like ParsedJwt instead
 *   * Jwt.verify calls Jwt.parse first then calls Jws.verify which effectively
 *     performs the same logic as Jwt.parse
 */

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

    if (header.typ == null || header.typ?.toUpperCase() != 'JWT') {
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

  static Future<void> verify(String signedJwt) async {
    Jwt.parse(signedJwt);

    return Jws.verify(signedJwt);
  }
}
