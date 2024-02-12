import 'dart:convert';
import 'dart:typed_data';

import 'package:web5/src/crypto.dart';
import 'package:web5/src/dids.dart';
import 'package:web5/src/extensions/base64url.dart';
import 'package:web5/src/jws/decoded_jws.dart';
import 'package:web5/src/jws/jws_header.dart';

final _base64UrlCodec = Base64Codec.urlSafe();
final _base64UrlEncoder = _base64UrlCodec.encoder;
final _base64UrlDecoder = _base64UrlCodec.decoder;

class Jws {
  static final _didResolver =
      DidResolver(methodResolvers: [DidJwk.resolver, DidDht.resolver]);

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
      payload = _base64UrlDecoder.convertNoPadding(parts[1]);
    } on Exception {
      throw Exception(
        'Malformed JWT. failed to decode claims',
      );
    }

    final Uint8List signature;
    try {
      signature = base64.decoder.convertNoPadding(parts[2]);
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

  /// Signs a JWT payload using a specified [Did] and returns the signed JWT.
  ///
  /// Throws [Exception] if any error occurs during the signing process.
  static Future<String> sign({
    required Did did,
    required Uint8List payload,
    JwsHeader? header,
    bool detachedPayload = false,
  }) async {
    final resolutionResult = await _didResolver.resolve(did.uri);
    if (resolutionResult.hasError()) {
      throw Exception('failed to resolve DID');
    }

    final verificationMethod =
        resolutionResult.didDocument!.verificationMethod!.first;

    final String kid;
    if (verificationMethod.id.startsWith('#')) {
      kid = '${did.uri}${verificationMethod.id}';
    } else {
      kid = verificationMethod.id;
    }

    final publicKeyJwk = verificationMethod.publicKeyJwk!;
    final dsaName = DsaName.findByAlias(
      algorithm: publicKeyJwk.alg,
      curve: publicKeyJwk.crv,
    );

    if (dsaName == null) {
      throw Exception('$dsaName signing not supported');
    }

    header ??= JwsHeader();
    header.kid = kid;
    header.alg = dsaName.algorithm;

    final headerBase64Url = header.toBase64Url();
    final payloadBase64Url = _base64UrlEncoder.convertNoPadding(payload);

    final toSign = '$headerBase64Url.$payloadBase64Url';
    final toSignBytes = Uint8List.fromList(utf8.encode(toSign));

    final keyAlias = publicKeyJwk.computeThumbprint();

    final signatureBytes = await did.keyManager.sign(keyAlias, toSignBytes);
    final signatureBase64Url =
        _base64UrlEncoder.convertNoPadding(signatureBytes);

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
