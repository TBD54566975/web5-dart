import 'package:web5/src/crypto.dart';
import 'package:web5/src/dids/data_models/did_resource.dart';

/// A DID document can express verification methods, such as cryptographic
/// public keys, which can be used to authenticate or authorize interactions
/// with the DID subject or associated parties. For example,
/// a cryptographic public key can be used as a verification method with
/// respect to a digital signature; in such usage, it verifies that the
/// signer could use the associated cryptographic private key
///
/// [Specification Reference](https://www.w3.org/TR/did-core/#verification-methods)
class DidVerificationMethod implements DidResource {
  @override
  final String id;
  final String type;
  final String controller;
  final Jwk? publicKeyJwk;
  final String? publicKeyMultibase;

  DidVerificationMethod({
    required this.id,
    required this.type,
    required this.controller,
    this.publicKeyJwk,
    this.publicKeyMultibase,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'type': type,
      'controller': controller,
      'publicKeyJwk': publicKeyJwk?.toJson(),
      'publicKeyMultibase': publicKeyMultibase,
    };

    json.removeWhere((key, value) => value == null);

    return json;
  }
}
