import 'package:web5/src/jwt.dart';
import 'package:web5/src/vc/vc.dart';

class DecodedVcJwt {
  VerifiableCredential vc;
  DecodedJwt jwt;

  DecodedVcJwt(this.vc, this.jwt);

  static DecodedVcJwt decode(String jwt) {
    final decoded = Jwt.decode(jwt);

    if (decoded.claims.misc == null || decoded.claims.misc!['vc'] == null) {
      throw Exception('vc-jwt missing vc claims');
    }

    final vc = VerifiableCredential.fromJson(decoded.claims.misc!['vc']);

    // the following conditionals are included to conform with the jwt decoding section
    // of the specification defined here: https://www.w3.org/TR/vc-data-model/#jwt-decoding
    if (decoded.claims.iss != null) {
      vc.issuer = decoded.claims.iss!;
    }

    if (decoded.claims.jti != null) {
      vc.id = decoded.claims.jti!;
    }

    if (decoded.claims.sub != null) {
      vc.subject = decoded.claims.sub!;
    }

    if (decoded.claims.exp != null) {
      vc.expirationDate =
          DateTime.fromMillisecondsSinceEpoch(decoded.claims.exp! * 1000)
              .toString();
    }

    if (decoded.claims.nbf != null) {
      vc.issuanceDate =
          DateTime.fromMillisecondsSinceEpoch(decoded.claims.nbf! * 1000)
              .toString();
    }

    return DecodedVcJwt(vc, decoded);
  }

  Future<void> verify() async {
    if (jwt.header.typ != 'JWT') {
      throw Exception('Invalid typ, must be "JWT"');
    }

    if (vc.issuer == '') {
      throw Exception('Missing issuer');
    }

    if (vc.id == '') {
      throw Exception('Missing id');
    }

    final issuanceDateTime = DateTime.parse(vc.issuanceDate);
    if (DateTime.now().isBefore(issuanceDateTime)) {
      throw Exception('VC cannot be used before ${vc.issuanceDate}');
    }

    if (vc.expirationDate != null) {
      final expirationDateTime = DateTime.parse(vc.expirationDate!);
      if (DateTime.now().isAfter(expirationDateTime)) {
        throw Exception('VC expired on ${vc.expirationDate}');
      }
    }

    if (vc.type.isEmpty) {
      throw Exception('Missing type');
    }

    if (!vc.type.contains(VerifiableCredential.baseType)) {
      throw Exception(
        'Missing base type: ${VerifiableCredential.baseContext}',
      );
    }

    if (vc.context.isEmpty) {
      throw Exception('Missing context');
    }

    if (!vc.context.contains(VerifiableCredential.baseContext)) {
      throw Exception(
        'Missing base context: ${VerifiableCredential.baseContext}',
      );
    }

    await jwt.verify();
  }
}
