import 'dart:convert';

import 'package:web5/src/extensions.dart';

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
