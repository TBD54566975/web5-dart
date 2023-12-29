import 'dart:convert';

import 'package:tbdex/src/crypto/key_manager.dart';
import 'package:tbdex/src/crypto/jwk.dart';

abstract class Did {
  String get uri;
  KeyManager get keyManager;
}

class DidUri {
  static final String pctEncodedPattern = r'(?:%[0-9a-fA-F]{2})';
  static final String idCharPattern = '(?:[a-zA-Z0-9._-]|$pctEncodedPattern)';
  static final String methodPattern = '([a-z0-9]+)';
  static final String methodIdPattern =
      '((?:$idCharPattern*:)*($idCharPattern+))';
  static final String paramCharPattern = '[a-zA-Z0-9_.:%-]';
  static final String paramPattern = ';$paramCharPattern+=$paramCharPattern*';
  static final String paramsPattern = '(($paramPattern)*)';
  static final String pathPattern = r'(/[^#?]*)?';
  static final String queryPattern = r'(\?[^\#]*)?';
  static final String fragmentPattern = r'(\#.*)?';
  static final RegExp didUriPattern = RegExp(
    '^did:$methodPattern:$methodIdPattern$paramsPattern$pathPattern$queryPattern$fragmentPattern\$',
  );

  String uri;
  String method;
  String id;
  Map<String, String>? params;
  String? path;
  String? query;
  String? fragment;

  DidUri({
    required this.uri,
    required this.method,
    required this.id,
    this.params,
    this.path,
    this.query,
    this.fragment,
  });

  static DidUri parse(String input) {
    final match = didUriPattern.firstMatch(input);

    if (match == null) {
      throw Exception("Invalid DID URI");
    }

    final [
      methodMatch,
      idMatch,
      paramsMatch,
      pathMatch,
      queryMatch,
      fragmentMatch
    ] = match.groups([1, 2, 4, 6, 7, 8]);

    final didUri = DidUri(
      uri: 'did:$methodMatch:$idMatch',
      method: methodMatch!,
      id: idMatch!,
    );

    if (paramsMatch!.isNotEmpty) {
      final params = paramsMatch.substring(1).split(';');
      final Map<String, String> parsedParams = {};
      for (final p in params) {
        final kv = p.split('=');
        parsedParams[kv[0]] = kv[1];
      }
      didUri.params = parsedParams;
    }

    if (pathMatch != null) didUri.path = pathMatch;
    if (queryMatch != null) didUri.query = queryMatch.substring(1);
    if (fragmentMatch != null) didUri.fragment = fragmentMatch.substring(1);

    return didUri;
  }
}

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
  final String id;
  final List<String>? alsoKnownAs;
  final dynamic controller; // String or List<String>

  /// cryptographic public keys, which can be used to authenticate or authorize
  /// interactions with the DID subject or associated parties.
  /// [spec reference](https://www.w3.org/TR/did-core/#verification-methods)
  final List<VerificationMethod>? verificationMethod;

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

/// Services are used in DID documents to express ways of communicating with
/// the DID subject or associated entities.
/// A service can be any type of service the DID subject wants to advertise.
///
/// [Specification Reference](https://www.w3.org/TR/did-core/#services)
class DidService {
  /// The value of the id property MUST be a URI conforming to [RFC3986].
  /// A conforming producer MUST NOT produce multiple service entries with
  /// the same id. A conforming consumer MUST produce an error if it detects
  /// multiple service entries with the same id.
  final String id;

  /// examples of registered types can be found
  /// [here](https://www.w3.org/TR/did-spec-registries/#service-types)
  final String type;

  /// A network address, such as an HTTP URL, at which services operate on behalf
  /// of a DID subject.
  final String serviceEndpoint;

  DidService({
    required this.id,
    required this.type,
    required this.serviceEndpoint,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'serviceEndpoint': serviceEndpoint,
    };
  }
}

/// A DID document can express verification methods, such as cryptographic
/// public keys, which can be used to authenticate or authorize interactions
/// with the DID subject or associated parties. For example,
/// a cryptographic public key can be used as a verification method with
/// respect to a digital signature; in such usage, it verifies that the
/// signer could use the associated cryptographic private key
///
/// [Specification Reference](https://www.w3.org/TR/did-core/#verification-methods)
class VerificationMethod {
  final String id;
  final String type;
  final String controller;
  final Jwk? publicKeyJwk;
  final String? publicKeyMultibase;

  VerificationMethod({
    required this.id,
    required this.type,
    required this.controller,
    this.publicKeyJwk,
    this.publicKeyMultibase,
  });

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

/// A metadata structure consisting of values relating to the results of the
/// DID resolution process which typically changes between invocations of the
/// resolve and resolveRepresentation functions, as it represents data about
/// the resolution process itself
///
/// [Specification Reference](https://www.w3.org/TR/did-core/#dfn-didresolutionmetadata)
class DidResolutionMetadata {
  /// The Media Type of the returned didDocumentStream. This property is
  /// REQUIRED if resolution is successful and if the resolveRepresentation
  /// function was called
  final String? contentType;

  /// The error code from the resolution process. This property is REQUIRED
  /// when there is an error in the resolution process. The value of this
  /// property MUST be a single keyword ASCII string. The possible property
  /// values of this field SHOULD be registered in the
  /// [DID Specification Registries](https://www.w3.org/TR/did-spec-registries/#error)
  final String? error;

  DidResolutionMetadata({
    this.contentType,
    this.error,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'contentType': contentType,
      'error': error,
    };

    json.removeWhere((key, value) => value == null);

    return json;
  }
}

class DidResolutionResult {
  DidResolutionMetadata? didResolutionMetadata;
  DidDocument? didDocument;
  DidDocumentMetadata? didDocumentMetadata;

  DidResolutionResult({
    this.didResolutionMetadata,
    this.didDocument,
    this.didDocumentMetadata,
  }) {
    didResolutionMetadata ??= DidResolutionMetadata();
    didDocumentMetadata ??= DidDocumentMetadata();
  }

  Map<String, dynamic> toJson() {
    return {
      'didResolutionMetadata': didResolutionMetadata?.toJson(),
      'didDocument': didDocument?.toJson(),
      'didDocumentMetadata': didDocumentMetadata?.toJson(),
    };
  }
}

/// contains metadata about the DID document contained in the didDocument
/// property. This metadata typically does not change between invocations of
/// the resolve and resolveRepresentation functions unless the DID document
/// changes, as it represents metadata about the DID document.
///
/// [Specification Reference](https://www.w3.org/TR/did-core/#dfn-diddocumentmetadata)
class DidDocumentMetadata {
  final String? created;
  final String? updated;
  final bool? deactivated;
  final String? versionId;
  final String? nextUpdate;
  final String? nextVersionId;
  final String? equivalentId;
  final String? canonicalId;

  DidDocumentMetadata({
    this.created,
    this.updated,
    this.deactivated,
    this.versionId,
    this.nextUpdate,
    this.nextVersionId,
    this.equivalentId,
    this.canonicalId,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'created': created,
      'updated': updated,
      'deactivated': deactivated,
      'versionId': versionId,
      'nextUpdate': nextUpdate,
      'nextVersionId': nextVersionId,
      'equivalentId': equivalentId,
      'canonicalId': canonicalId,
    };

    json.removeWhere((key, value) => value == null);

    return json;
  }
}
