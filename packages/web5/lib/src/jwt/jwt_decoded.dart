import 'package:web5/src/jwt/jwt_claims.dart';
import 'package:web5/src/jwt/jwt_header.dart';

/// Represents a decoded JWT, including both its header and payload.
///
/// **Note**: Signature not included because its decoded form would be bytes
class JwtDecoded {
  final JwtHeader header;
  final JwtClaims payload;

  JwtDecoded({required this.header, required this.payload});

  factory JwtDecoded.fromJson(Map<String, dynamic> json) {
    return JwtDecoded(
      header: JwtHeader.fromJson(json['header']),
      payload: JwtClaims.fromJson(json['payload']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'header': header.toJson(),
      'payload': payload.toJson(),
    };
  }
}
