import 'package:collection/collection.dart';
import 'package:web5/src/dids/did_core/did_service.dart';
import 'package:web5/src/dids/did_core/did_resource.dart';
import 'package:web5/src/dids/did_core/did_verification_method.dart';
import 'package:web5/src/dids/did_core/did_verification_relationship.dart';

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
class DidDocument implements DidResource {
  final String? context;

  /// The DID URI for a particular DID subject is expressed using the id property
  /// in the DID document.
  @override
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
  List<DidVerificationMethod>? verificationMethod;

  /// Services are used in DID documents to express ways of communicating with
  /// the DID subject or associated entities.
  /// A service can be any type of service the DID subject wants to advertise.
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#services)
  List<DidService>? service;

  /// The assertionMethod verification relationship is used to specify how the
  /// DID subject is expected to express claims, such as for the purposes of
  /// issuing a Verifiable Credential
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#assertion)
  List<String>? assertionMethod;

  /// The authentication verification relationship is used to specify how the
  /// DID subject is expected to be authenticated, for purposes such as logging
  /// into a website or engaging in any sort of challenge-response protocol.
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#key-agreement)
  List<String>? authentication;

  /// The keyAgreement verification relationship is used to specify how an
  /// entity can generate encryption material in order to transmit confidential
  /// information intended for the DID subject, such as for the purposes of
  /// establishing a secure communication channel with the recipient
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#authentication)
  List<String>? keyAgreement;

  /// The capabilityDelegation verification relationship is used to specify a
  /// mechanism that might be used by the DID subject to delegate a
  /// cryptographic capability to another party, such as delegating the
  /// authority to access a specific HTTP API to a subordinate.
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#capability-delegation)
  List<String>? capabilityDelegation;

  /// The capabilityInvocation verification relationship is used to specify a
  /// verification method that might be used by the DID subject to invoke a
  /// cryptographic capability, such as the authorization to update the
  /// DID Document
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#capability-invocation)
  List<String>? capabilityInvocation;

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

  void addVerificationMethod(
    DidVerificationMethod vm, {
    VerificationPurpose? purpose,
  }) {
    verificationMethod ??= [];
    verificationMethod!.add(vm);

    if (purpose != null) {
      addVerificationPurpose(purpose, vm.id);
    }
  }

  void addVerificationPurpose(
    VerificationPurpose purpose,
    String id,
  ) {
    if (purpose == VerificationPurpose.authentication) {
      authentication ??= [];
      authentication!.add(id);
    } else if (purpose == VerificationPurpose.assertionMethod) {
      assertionMethod ??= [];
      assertionMethod!.add(id);
    } else if (purpose == VerificationPurpose.capabilityDelegation) {
      capabilityDelegation ??= [];
      capabilityDelegation!.add(id);
    } else if (purpose == VerificationPurpose.capabilityInvocation) {
      capabilityInvocation ??= [];
      capabilityInvocation!.add(id);
    } else if (purpose == VerificationPurpose.keyAgreement) {
      keyAgreement ??= [];
      keyAgreement!.add(id);
    }
  }

  DidVerificationMethod? getVerificationMethod({
    String? id,
    VerificationPurpose? purpose,
  }) {
    if (id == null && verificationMethod == null) {
      return verificationMethod?.first;
    }

    if (id != null) {
      final idVariations = getResourceIdVariations(id);

      return verificationMethod
          ?.firstWhereOrNull((vm) => idVariations.contains(vm.id));
    }

    String? vmId;

    if (purpose == VerificationPurpose.authentication) {
      vmId = authentication?.first;
    } else if (purpose == VerificationPurpose.assertionMethod) {
      vmId = assertionMethod?.first;
    } else if (purpose == VerificationPurpose.capabilityDelegation) {
      vmId = capabilityDelegation?.first;
    } else if (purpose == VerificationPurpose.capabilityInvocation) {
      vmId = capabilityInvocation?.first;
    } else if (purpose == VerificationPurpose.keyAgreement) {
      vmId = keyAgreement?.first;
    }

    if (vmId == null) {
      return null;
    }

    final idVariations = getResourceIdVariations(vmId);

    return verificationMethod
        ?.firstWhereOrNull((vm) => idVariations.contains(vm.id));
  }

  void addService(DidService svc) {
    service ??= [];
    service!.add(svc);
  }

  DidResource? getResourceById(String resourceId) {
    if (resourceId == id) {
      return this;
    }

    final Set<String> idVariations = getResourceIdVariations(resourceId);

    DidResource? resource = verificationMethod
        ?.firstWhereOrNull((vm) => idVariations.contains(vm.id));

    if (resource != null) {
      return resource;
    }

    resource = service?.firstWhereOrNull((vm) => idVariations.contains(vm.id));

    return resource;
  }

  Set<String> getResourceIdVariations(String providedId) {
    final Set<String> idVariations = {providedId};
    if (providedId.startsWith('#')) {
      idVariations.add('$id$providedId');
    } else {
      final splitId = providedId.split('#');
      if (splitId.length > 1) {
        idVariations.add('#${splitId[1]}');
      }
    }

    return idVariations;
  }

  @override
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

  factory DidDocument.fromJson(Map<String, dynamic> json) {
    return DidDocument(
      context: json['context'],
      id: json['id'],
      alsoKnownAs: json['alsoKnownAs']?.cast<String>(),
      controller: json['controller'],
      verificationMethod: (json['verificationMethod'] as List<dynamic>?)
          ?.map((item) => DidVerificationMethod.fromJson(item))
          .toList(),
      service: (json['service'] as List<dynamic>?)
          ?.map((item) => DidService.fromJson(item))
          .toList(),
      assertionMethod: json['assertionMethod']?.cast<String>(),
      authentication: json['authentication']?.cast<String>(),
      keyAgreement: json['keyAgreement']?.cast<String>(),
      capabilityDelegation: json['capabilityDelegation']?.cast<String>(),
      capabilityInvocation: json['capabilityInvocation']?.cast<String>(),
    );
  }
}
