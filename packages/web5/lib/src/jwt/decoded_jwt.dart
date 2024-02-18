import 'dart:typed_data';

import 'package:web5/src/encoders.dart';
import 'package:web5/src/jws/decoded_jws.dart';
import 'package:web5/src/jwt/jwt_claims.dart';
import 'package:web5/src/jwt/jwt_header.dart';

class DecodedJwt {
  final JwtHeader header;
  final JwtClaims claims;
  final Uint8List signature;
  final List<String> parts;

  DecodedJwt({
    required this.header,
    required this.claims,
    required this.signature,
    required this.parts,
  });

  Future<void> verify() async {
    final decodedJws = DecodedJws(
      header: header,
      payload: Base64Url.decode(parts[1]),
      signature: signature,
      parts: parts,
    );

    await decodedJws.verify();
  }
}
