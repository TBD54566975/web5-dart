import 'dart:convert';
import 'dart:typed_data';

import 'package:web5/src/common.dart';
import 'package:web5/src/crypto/crypto.dart';
import 'package:web5/src/dids.dart';
import 'package:web5/src/crypto/jws/decoded.dart';
import 'package:web5/src/crypto/jws/header.dart';

class Jws {
  static DecodedJws decode(String jws) {
    final parts = jws.split('.');

    if (parts.length != 3) {
      throw Exception(
        'Malformed JWT. expected 3 parts. got ${parts.length}',
      );
    }

    final JwsHeader header;
    try {
      header = JwsHeader.fromBase64Url(parts[0]);
    } on Exception {
      throw Exception(
        'Malformed JWT. failed to decode header',
      );
    }

    final Uint8List payload;
    try {
      payload = Base64Url.decode(parts[1]);
    } on Exception {
      throw Exception(
        'Malformed JWT. failed to decode claims',
      );
    }

    final Uint8List signature;
    try {
      signature = Base64Url.decode(parts[2]);
    } on Exception {
      throw Exception(
        'Malformed JWT: Failed to decode signature',
      );
    }

    return DecodedJws(
      header: header,
      payload: payload,
      signature: signature,
      parts: parts,
    );
  }

  /// Signs a JWT payload using a specified [BearerDid] and returns the signed JWT.
  ///
  /// Throws [Exception] if any error occurs during the signing process.
  static Future<String> sign({
    required BearerDid did,
    required Uint8List payload,
    JwsHeader? header,
    bool detachedPayload = false,
  }) async {
    final signer = await did.getSigner();

    final String kid;
    if (signer.verificationMethod.id.startsWith('#')) {
      kid = '${did.uri}${signer.verificationMethod.id}';
    } else {
      kid = signer.verificationMethod.id;
    }

    final publicKeyJwk = signer.verificationMethod.publicKeyJwk!;

    header ??= JwsHeader();
    header.kid = kid;
    header.alg = Crypto.getJwa(publicKeyJwk);

    final headerBase64Url = header.toBase64Url();
    final payloadBase64Url = Base64Url.encode(payload);

    final toSign = '$headerBase64Url.$payloadBase64Url';
    final toSignBytes = Uint8List.fromList(utf8.encode(toSign));

    final signatureBytes = await signer.sign(toSignBytes);
    final signatureBase64Url = Base64Url.encode(signatureBytes);

    if (detachedPayload) {
      return '$headerBase64Url..$signatureBase64Url';
    } else {
      return '$headerBase64Url.$payloadBase64Url.$signatureBase64Url';
    }
  }

  static Future<DecodedJws> verify(String jws) async {
    try {
      final decodedJws = decode(jws);
      await decodedJws.verify();
      return decodedJws;
    } on Exception catch (e) {
      throw Exception('Verification failed. $e');
    }
  }
}
