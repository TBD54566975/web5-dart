import 'package:web5/src/crypto/dsa_alias.dart';

/// Enum [DsaName] representing supported Digital Signature Algorithm (DSA) names.
enum DsaName {
  secp256k1('ES256K', 'secp256k1', 'EC'),
  ed25519('EdDSA', 'Ed25519', 'OKP');

  static final _aliases = {
    DsaAlias(algorithm: 'EdDSA', curve: 'Ed25519'): DsaName.ed25519,
    DsaAlias(algorithm: null, curve: 'Ed25519'): DsaName.ed25519,
    DsaAlias(algorithm: 'ES256K', curve: 'secp256k1'): DsaName.secp256k1,
    DsaAlias(algorithm: 'ES256K', curve: null): DsaName.secp256k1,
    DsaAlias(algorithm: null, curve: 'secp256k1'): DsaName.secp256k1,
  };

  final String algorithm;
  final String curve;
  final String kty;

  const DsaName(this.algorithm, this.curve, this.kty);

  /// method that can be used to find [DsaName] using
  /// [JWA](https://datatracker.ietf.org/doc/html/rfc7518.html) algorithm and
  /// curve names
  static DsaName? findByAlias({String? algorithm, String? curve}) =>
      _aliases[DsaAlias(algorithm: algorithm, curve: curve)];
}
