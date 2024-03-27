import 'dart:convert';

import 'package:web5/src/common.dart';
import 'package:web5/src/dids.dart';
import 'package:web5/src/jws/jws.dart';
import 'package:web5/src/jwt/decoded.dart';
import 'package:web5/src/jwt/claims.dart';
import 'package:web5/src/jwt/header.dart';

class Jwt {
  static DecodedJwt decode(String jwt) {
    final decodedJws = Jws.decode(jwt);

    final JwtClaims claims;
    try {
      final str = utf8.decode(decodedJws.payload);
      claims = JwtClaims.fromJson(json.decode(str));
    } on Exception {
      throw Exception(
        'Malformed JWT. Invalid base64url encoding for JWT payload',
      );
    }

    return DecodedJwt(
      header: decodedJws.header,
      claims: claims,
      signature: decodedJws.signature,
      parts: decodedJws.parts,
    );
  }

  /// Signs a JWT payload using a specified [BearerDid] and returns the signed JWT.
  ///
  /// Throws [Exception] if any error occurs during the signing process.
  static Future<String> sign({
    required BearerDid did,
    required JwtClaims payload,
  }) async {
    final header = JwtHeader(typ: 'JWT');
    final payloadBytes = json.toBytes(payload.toJson());

    return Jws.sign(did: did, payload: payloadBytes, header: header);
  }

  static Future<DecodedJwt> verify(String jwt) async {
    final decodedJwt = decode(jwt);
    await decodedJwt.verify();
    return decodedJwt;
  }
}
