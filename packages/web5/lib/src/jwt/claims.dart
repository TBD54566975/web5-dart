import 'dart:convert';

import 'package:web5/src/common.dart';

final Set<String> reservedClaims = {
  'iss',
  'sub',
  'aud',
  'exp',
  'nbf',
  'iat',
  'jti',
};

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
  String? aud;

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

  Map<String, dynamic>? misc; // Additional arbitrary claims.

  JwtClaims({
    this.iss,
    this.sub,
    this.aud,
    this.exp,
    this.nbf,
    this.iat,
    this.jti,
    misc,
  }) : misc = misc ?? {};

  Map<String, dynamic> toJson() {
    final map = {
      if (iss != null) 'iss': iss,
      if (sub != null) 'sub': sub,
      if (aud != null) 'aud': aud,
      if (exp != null) 'exp': exp,
      if (nbf != null) 'nbf': nbf,
      if (iat != null) 'iat': iat,
      if (jti != null) 'jti': jti,
    };

    if (misc != null) {
      map.addAll(misc!);
    }

    return map;
  }

  factory JwtClaims.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> miscClaims = {};

    for (final key in json.keys) {
      if (reservedClaims.contains(key)) {
        continue;
      }

      miscClaims[key] = json[key];
    }

    return JwtClaims(
      iss: json['iss'] as String?,
      sub: json['sub'] as String?,
      aud: json['aud'] as String?,
      exp: json['exp'] as int?,
      nbf: json['nbf'] as int?,
      iat: json['iat'] as int?,
      jti: json['jti'] as String?,
      misc: miscClaims,
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
