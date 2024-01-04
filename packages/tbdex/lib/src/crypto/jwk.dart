import 'dart:convert';
import 'package:cryptography/dart.dart';
import 'package:tbdex/src/extensions/base64url.dart';
import 'package:tbdex/src/extensions/json.dart';

// TODO: refactor into PrivateJwk PublicJwk classes

const dartSha256 = DartSha256();

/// Represents a [JSON Web Key (JWK)](https://datatracker.ietf.org/doc/html/rfc7517).
///
/// A JWK is a JSON object that represents a cryptographic key. This class
/// provides functionalities to manage a JWK including its creation, conversion
/// to and from JSON, and computing a thumbprint.
///
/// The following fields are defined in the class:
/// - [kty]: Represents the key type.
/// - [use]: Represents the intended use of the public key.
/// - [alg]: Identifies the algorithm intended for use with the key.
/// - [kid]: Key ID, unique identifier for the key.
/// - [crv]: Elliptic curve name for EC keys.
/// - [d]: Private key component for EC or OKP keys.
/// - [x]: X coordinate for EC keys, or the public key for OKP.
/// - [y]: Y coordinate for EC keys.
///
/// An optional parameter [kidFromThumbprint] determines if the key ID ([kid])
/// should be computed from the thumbprint when not provided.
///
/// Example:
/// ```
/// var jwk = Jwk(
///   kty: 'RSA',
///   alg: 'RS256',
///   use: 'sig',
///   ... // other parameters
/// );
/// ```
class Jwk {
  /// Represents the key type. e.g. EC for elliptic curve, OKP for Edwards curve
  final String kty;

  /// Represents the intended use of the public key.
  final String? use;

  /// Identifies the algorithm intended for use with the key.
  final String? alg;

  /// Key ID, unique identifier for the key.
  late final String? kid;

  /// curve name for Elliptic Curve (EC) and Edwards Curve (Ed) keys.
  /// e.g. secp256k1, Ed25519
  final String? crv;

  /// Private key component for EC or OKP keys.
  final String? d;

  /// X coordinate for EC keys, or the public key for OKP.
  final String? x;

  /// Y coordinate for EC keys.
  final String? y;

  /// Constructs a [Jwk] instance with specified parameters.
  /// If [kid] is not provided and [kidFromThumbprint] is true, the [kid]
  /// is computed using a thumbprint of the key.
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

  /// Creates a [Jwk] instance from a JSON map.
  ///
  /// Parses the provided JSON map and creates a [Jwk] instance.
  /// The JSON map should contain the necessary JWK parameters.
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

  /// Converts this [Jwk] instance to a JSON map.
  ///
  /// Returns a map representation of the JWK. Null fields are omitted
  /// from the resulting map.
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

  /// Computes the thumbprint of the JWK.
  /// [Specification](https://www.rfc-editor.org/rfc/rfc7638.html).
  ///
  /// Generates a thumbprint of the JWK using SHA-256 hash function.
  /// The thumbprint is computed based on the key's [kty], [crv], [x],
  /// and [y] values.
  ///
  /// Returns a Base64URL-encoded string representing the thumbprint.
  String computeThumbprint() {
    final thumbprintPayload = {crv: crv, kty: kty, x: x, y: y};
    thumbprintPayload.removeWhere((key, value) => value == null);

    final thumbprintPayloadBytes = utf8.encode(jsonEncode(thumbprintPayload));
    final thumbprintPayloadDigest = dartSha256.hashSync(thumbprintPayloadBytes);

    final thumbprint =
        base64UrlEncoder.convertNoPadding(thumbprintPayloadDigest.bytes);

    return thumbprint;
  }
}
