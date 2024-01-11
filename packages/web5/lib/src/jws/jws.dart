import 'dart:convert';
import 'dart:typed_data';

import 'package:web5/src/dids.dart';
import 'package:web5/src/crypto.dart';
import 'package:web5/src/extensions.dart';
import 'package:web5/src/jws/jws_header.dart';

final _base64UrlCodec = Base64Codec.urlSafe();
final _base64UrlEncoder = _base64UrlCodec.encoder;
final _base64UrlDecoder = _base64UrlCodec.decoder;

class Jws {
  static final _didResolver =
      DidResolver(methodResolvers: [DidJwk.resolver, DidDht.resolver]);

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

  static Future<void> verify(String compactJws, {Uint8List? payload}) async {
    final splitJws = compactJws.split('.');

    if (splitJws.length != 3) {
      throw Exception(
        'Malformed JWS. expected 3 parts. got ${splitJws.length}',
      );
    }

    final [
      base64UrlEncodedHeader,
      base64UrlEncodedPayload,
      base64UrlEncodedSignature
    ] = splitJws;

    final JwsHeader header;
    try {
      header = JwsHeader.fromBase64Url(base64UrlEncodedHeader);
    } on Exception {
      throw Exception(
        'Malformed JWS. Invalid base64url encoding for JWS header',
      );
    }

    if (header.kid == null || header.alg == null) {
      throw Exception(
        'Malformed JWS. expected header to contain kid and alg.',
      );
    }

    try {
      payload ??= _base64UrlDecoder.convertNoPadding(base64UrlEncodedPayload);
    } on Exception {
      throw Exception(
        'Malformed JWS. Invalid base64url encoding for JWS payload',
      );
    }

    final Uint8List signature;
    try {
      signature = _base64UrlDecoder.convertNoPadding(base64UrlEncodedSignature);
    } on Exception {
      throw Exception(
        'Malformed JWS. Invalid base64url encoding for JWS signature',
      );
    }

    final dereferenceResult = await _didResolver.dereference(header.kid!);

    if (dereferenceResult.hasError()) {
      throw Exception(
        'Verification failed. Failed to dereference kid. Error: ${dereferenceResult.dereferencingMetadata.error}',
      );
    }

    final didResource = dereferenceResult.contentStream;
    if (didResource == null) {
      throw Exception(
        'Verification failed. Expected header kid to dereference a verification method',
      );
    }

    if (didResource is! DidVerificationMethod) {
      throw Exception(
        'Verification failed. Expected header kid to dereference a verification method',
      );
    }

    final publicKeyJwk = didResource.publicKeyJwk;
    final dsaName =
        DsaName.findByAlias(algorithm: header.alg, curve: publicKeyJwk!.crv);

    if (dsaName == null) {
      throw Exception('${header.alg}:${publicKeyJwk.crv} not supported.');
    }

    return DsaAlgorithms.verify(
      algName: dsaName,
      publicKey: publicKeyJwk,
      payload: payload,
      signature: signature,
    );
  }
}
