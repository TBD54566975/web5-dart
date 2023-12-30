import 'package:tbdex/src/dids/did_service.dart';
import 'package:tbdex/src/dids/did_verification_method.dart';

/// A set of data describing the DID subject including mechanisms such as:
///  * cryptographic public keys - used to authenticate itself and prove
///                                association with the DID
///  * services - means of communicating or interacting with the DID subject or
///               associated entities via one or more service endpoints.
///               Examples include discovery services, agent services,
///               social networking services, file storage services,
///               and verifiable credential repository services.
///
/// A DID Document can be retrieved by _resolving_ a DID URI
class DidDocument {
  final String? context;

  /// The DID URI for a particular DID subject is expressed using the id property
  /// in the DID document.
  final String id;

  /// A DID subject can have multiple identifiers for different purposes, or at
  /// different times. The assertion that two or more DIDs (or other types of URI)
  /// refer to the same DID subject can be made using the alsoKnownAs property.
  final List<String>? alsoKnownAs;

  /// A DID controller is an entity that is authorized to make changes to a
  /// DID document. The process of authorizing a DID controller is defined
  /// by the DID method.
  final dynamic controller; // String or List<String>

  /// cryptographic public keys, which can be used to authenticate or authorize
  /// interactions with the DID subject or associated parties.
  /// [spec reference](https://www.w3.org/TR/did-core/#verification-methods)
  final List<DidVerificationMethod>? verificationMethod;

  /// Services are used in DID documents to express ways of communicating with
  /// the DID subject or associated entities.
  /// A service can be any type of service the DID subject wants to advertise.
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#services)
  final List<DidService>? service;

  /// The assertionMethod verification relationship is used to specify how the
  /// DID subject is expected to express claims, such as for the purposes of
  /// issuing a Verifiable Credential
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#assertion)
  final List<String>? assertionMethod;

  /// The authentication verification relationship is used to specify how the
  /// DID subject is expected to be authenticated, for purposes such as logging
  /// into a website or engaging in any sort of challenge-response protocol.
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#key-agreement)
  final List<String>? authentication;

  /// The keyAgreement verification relationship is used to specify how an
  /// entity can generate encryption material in order to transmit confidential
  /// information intended for the DID subject, such as for the purposes of
  /// establishing a secure communication channel with the recipient
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#authentication)
  final List<String>? keyAgreement;

  /// The capabilityDelegation verification relationship is used to specify a
  /// mechanism that might be used by the DID subject to delegate a
  /// cryptographic capability to another party, such as delegating the
  /// authority to access a specific HTTP API to a subordinate.
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#capability-delegation)
  final List<String>? capabilityDelegation;

  /// The capabilityInvocation verification relationship is used to specify a
  /// verification method that might be used by the DID subject to invoke a
  /// cryptographic capability, such as the authorization to update the
  /// DID Document
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#capability-invocation)
  final List<String>? capabilityInvocation;

  DidDocument({
    this.context,
    required this.id,
    this.alsoKnownAs,
    this.controller,
    this.verificationMethod,
    this.service,
    this.assertionMethod,
    this.authentication,
    this.keyAgreement,
    this.capabilityDelegation,
    this.capabilityInvocation,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'context': context,
      'id': id,
      'alsoKnownAs': alsoKnownAs,
      'controller': controller,
      'verificationMethod':
          verificationMethod?.map((vm) => vm.toJson()).toList(),
      'service': service?.map((s) => s.toJson()).toList(),
      'assertionMethod': assertionMethod,
      'authentication': authentication,
      'keyAgreement': keyAgreement,
      'capabilityDelegation': capabilityDelegation,
      'capabilityInvocation': capabilityInvocation,
    };

    json.removeWhere((key, value) => value == null);

    return json;
  }
}
