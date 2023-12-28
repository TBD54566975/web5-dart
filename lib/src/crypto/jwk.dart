import 'dart:convert';
import 'package:cryptography/dart.dart';

// TODO: refactor into PrivateJwk PublicJwk classes

const dartSha256 = DartSha256();

class Jwk {
  final String kty; // Key Type
  final String? use; // Public Key Use
  final String? alg; // Algorithm
  late final String? kid; // Key ID
  final String? crv; // Curve
  final String? d; // EC or OKP Private Key
  final String? x; // X Coordinate for EC, or Public Key for OKP
  final String? y; // Y Coordinate for EC

  Jwk({
    required this.kty,
    this.use,
    this.alg,
    String? kid,
    this.crv,
    this.d,
    this.x,
    this.y,
    bool kidFromThumbprint = true,
  }) {
    if (kid == null && kidFromThumbprint) {
      this.kid = computeThumbprint();
    } else {
      this.kid = kid;
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
  String toString() => jsonEncode(toJson());

  String computeThumbprint() {
    final thumbprintPayload = {crv: crv, kty: kty, x: x, y: y};
    thumbprintPayload.removeWhere((key, value) => value == null);

    final thumbprintPayloadBytes = utf8.encode(jsonEncode(thumbprintPayload));
    final thumbprintPayloadDigest = dartSha256.hashSync(thumbprintPayloadBytes);

    final thumbprint =
        base64UrlEncode(thumbprintPayloadDigest.bytes).replaceAll("=", '');

    return thumbprint;
  }
}
