import 'dart:convert';
import 'package:cryptography/dart.dart';

// TODO: refactor into PrivateJwk PublicJwk classes

const dartSha256 = DartSha256();

class Jwk {
  String kty; // Key Type
  String? use; // Public Key Use
  String? alg; // Algorithm
  String? kid; // Key ID
  String? crv; // Curve
  String? d; // EC or OKP Private Key
  String? x; // X Coordinate for EC, or Public Key for OKP
  String? y; // Y Coordinate for EC

  Jwk(
      {required this.kty,
      this.use,
      this.alg,
      this.kid,
      this.crv,
      this.d,
      this.x,
      this.y,
      bool kidFromThumbprint = true}) {
    if (kid == null && kidFromThumbprint == true) {
      kid = computeThumbprint();
    }
  }

  factory Jwk.fromJson(Map<String, dynamic> json) {
    return Jwk(
      kty: json['kty'],
      use: json['use'],
      alg: json['alg'],
      kid: json['kid'],
      crv: json['crv'],
      d: json['d'],
      x: json['x'],
      y: json['y'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'kty': kty,
      'use': use,
      'alg': alg,
      'kid': kid,
      'crv': crv,
      'd': d,
      'x': x,
      'y': y,
    };

    json.removeWhere((key, value) => value == null);
    return json;
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  String computeThumbprint() {
    var thumbprintPayload = {crv: crv, kty: kty, x: x, y: y};
    thumbprintPayload.removeWhere((key, value) => value == null);

    var thumbprintPayloadBytes = utf8.encode(jsonEncode(thumbprintPayload));
    var thumbprintPayloadDigest = dartSha256.hashSync(thumbprintPayloadBytes);

    var thumbprint =
        base64UrlEncode(thumbprintPayloadDigest.bytes).replaceAll("=", '');

    return thumbprint;
  }
}
