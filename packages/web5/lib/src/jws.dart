import 'dart:convert';
import 'dart:typed_data';

import 'package:web5/src/crypto/dsa.dart';
import 'package:web5/src/crypto/dsa_algorithms.dart';
import 'package:web5/src/dids/did.dart';
import 'package:web5/src/dids/did_dht.dart';
import 'package:web5/src/dids/did_jwk.dart';
import 'package:web5/src/dids/did_resolver.dart';
import 'package:web5/src/dids/verification_method.dart';
import 'package:web5/src/extensions/base64url.dart';
import 'package:web5/src/extensions/json.dart';

final _base64UrlCodec = Base64Codec.urlSafe();
final _base64UrlEncoder = _base64UrlCodec.encoder;

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
      algorithm: publicKeyJwk.alg,
      curve: publicKeyJwk.crv,
    );

    if (dsaName == null) {
      throw Exception("$dsaName signing not supported");
    }

    header ??= JwsHeader();
    header.kid = kid;
    header.alg = dsaName.algorithm;

    final headerBase64Url = header.toBase64Url();
    final payloadBase64Url = _base64UrlEncoder.convertNoPadding(payload);

    final toSign = "$headerBase64Url.$payloadBase64Url";
    final toSignBytes = Uint8List.fromList(utf8.encode(toSign));

    final keyAlias = publicKeyJwk.computeThumbprint();

    final signatureBytes = await did.keyManager.sign(keyAlias, toSignBytes);
    final signatureBase64Url =
        _base64UrlEncoder.convertNoPadding(signatureBytes);

    if (detachedPayload) {
      return "$headerBase64Url..$signatureBase64Url";
    } else {
      return "$headerBase64Url.$payloadBase64Url.$signatureBase64Url";
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
      payload ??= base64UrlDecoder.convertNoPadding(base64UrlEncodedPayload);
    } on Exception {
      throw Exception(
        'Malformed JWS. Invalid base64url encoding for JWS payload',
      );
    }

    final Uint8List signature;
    try {
      signature = base64UrlDecoder.convertNoPadding(base64UrlEncodedSignature);
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
      throw Exception("${header.alg}:${publicKeyJwk.crv} not supported.");
    }

    return DsaAlgorithms.verify(
      algName: dsaName,
      publicKey: publicKeyJwk,
      payload: payload,
      signature: signature,
    );
  }
}

/// Represents the header portion of a JWS.
class JwsHeader {
  /// The "typ" (type) Header Parameter is used by JWS applications to
  /// declare the media type [IANA.MediaTypes](https://www.iana.org/assignments/media-types/media-types.xhtml)
  /// of this complete JWS.  This is intended for use by the application when
  /// more than one kind of object could be present in an application data
  /// structure that can contain a JWS;
  ///
  /// [Specification Reference](https://datatracker.ietf.org/doc/html/rfc7515#section-4.1.9)
  String? typ;

  ///  The "alg" (algorithm) Header Parameter identifies the cryptographic
  /// algorithm used to secure the JWS.  The JWS Signature value is not
  /// valid if the "alg" value does not represent a supported algorithm or
  /// if there is not a key for use with that algorithm associated with the
  /// party that digitally signed or MACed the content.  "alg" values
  /// should either be registered in the IANA "JSON Web Signature and
  /// Encryption Algorithms" registry established by JWA or be a value
  /// that contains a Collision-Resistant Name.  The "alg" value is a case-
  /// sensitive ASCII string containing a StringOrURI value.  This Header
  /// Parameter MUST be present and MUST be understood and processed by
  /// implementations.
  ///
  /// [Specification reference](https://datatracker.ietf.org/doc/html/rfc7515#section-4.1.1)
  String? alg;

  /// The "kid" (key ID) Header Parameter is a hint indicating which key
  /// was used to secure the JWS.  This parameter allows originators to
  /// explicitly signal a change of key to recipients.  The structure of
  /// the "kid" value is unspecified.  Its value MUST be a case-sensitive
  /// string.
  ///
  /// [Specification reference](https://datatracker.ietf.org/doc/html/rfc7515#section-4.1.4)
  String? kid;

  JwsHeader({this.typ, this.alg, this.kid});

  Map<String, dynamic> toJson() {
    return {
      if (typ != null) 'typ': typ,
      if (alg != null) 'alg': alg,
      if (kid != null) 'kid': kid,
    };
  }

  /// decodes a base64url string into a jws header
  factory JwsHeader.fromBase64Url(String base64UrlEncodedHeader) {
    final jsonHeader = json.fromBase64Url(base64UrlEncodedHeader);

    return JwsHeader.fromJson(jsonHeader);
  }

  factory JwsHeader.fromJson(Map<String, dynamic> json) {
    return JwsHeader(
      typ: json['typ'] as String?,
      alg: json['alg'] as String?,
      kid: json['kid'] as String?,
    );
  }

  /// base64url encodes (no-padding) the JWS header as per the
  /// [JWS Specification](https://datatracker.ietf.org/doc/html/rfc7515#appendix-C)
  String toBase64Url() {
    final jsonHeader = toJson();
    return json.toBase64Url(jsonHeader);
  }
}
