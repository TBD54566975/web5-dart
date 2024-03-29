import 'package:web5/src/crypto.dart';
import 'package:web5/src/dids/did_core/did_resource.dart';
import 'package:web5/src/dids/did_core/did_verification_relationship.dart';

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

  factory DidVerificationMethod.fromJson(Map<String, dynamic> json) {
    return DidVerificationMethod(
      id: json['id'],
      type: json['type'],
      controller: json['controller'],
      publicKeyJwk: json['publicKeyJwk'] != null
          ? Jwk.fromJson(json['publicKeyJwk'])
          : null,
      publicKeyMultibase: json['publicKeyMultibase'],
    );
  }
}

class DidCreateVerificationMethod {
  DidCreateVerificationMethod({
    required this.controller,
    this.id,
    required this.purposes,
    required this.type,
  });

  final String controller;
  final String? id;
  final List<VerificationPurpose> purposes;
  final String type;
}
