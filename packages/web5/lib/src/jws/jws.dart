import 'dart:convert';
import 'dart:typed_data';

import 'package:web5/src/crypto.dart';
import 'package:web5/src/encoders.dart';
import 'package:web5/src/dids.dart';
import 'package:web5/src/jws/decoded_jws.dart';
import 'package:web5/src/jws/jws_header.dart';

class Jws {
  /// Decodes a compact JWS per [RFC 7515](https://tools.ietf.org/html/rfc7515)
  /// and returns a [DecodedJws] object.
  ///
  /// ### Note
  /// `detachedPayload` is optional and should be provided if the payload
  /// is detached. More information on detached payloads can be found
  /// [here](https://tools.ietf.org/html/rfc7515#section-7.2).
  static DecodedJws decode(String jws, {Uint8List? detachedPayload}) {
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
    if (detachedPayload == null) {
      try {
        payload = Base64Url.decode(parts[1]);
      } on Exception {
        throw Exception(
          'Malformed JWT. failed to decode claims',
        );
      }
    } else {
      payload = detachedPayload;
      parts[1] = Base64Url.encode(detachedPayload);
    }

    final Uint8List signature;
    try {
      signature = Base64Url.decode(parts[2]);
    } on Exception {
      throw Exception(
        'Malformed JWT. faild to decode signature',
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

  /// Verifies a compact JWS per [RFC 7515](https://tools.ietf.org/html/rfc7515)
  /// and returns a [DecodedJws] object. Throws [Exception] if verification fails.
  ///
  /// ### Note
  /// `detachedPayload` is optional and should be provided if the payload
  /// is detached. More information on detached payloads can be found
  /// [here](https://tools.ietf.org/html/rfc7515#section-7.2).
  static Future<DecodedJws> verify(
    String jws, {
    Uint8List? detachedPayload,
  }) async {
    try {
      final decodedJws = decode(jws, detachedPayload: detachedPayload);
      await decodedJws.verify();
      return decodedJws;
    } on Exception catch (e) {
      throw Exception('Verification failed. $e');
    }
  }
}
