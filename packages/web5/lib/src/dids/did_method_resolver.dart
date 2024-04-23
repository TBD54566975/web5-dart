import 'dart:io';

import 'package:web5/src/dids/did.dart';
import 'package:web5/src/dids/did_core.dart';

/// Represents a method resolver for a specific DID method.
class DidMethodResolver {
  /// The name of the DID method e.g. jwk, dht, web
  String name;

  /// The function to resolve a DID URI using this method.
  Future<DidResolutionResult> Function(Did, {HttpClient? client}) resolve;

  /// Constructs a [DidMethodResolver] with a given [name] and [resolve] function.
  DidMethodResolver({required this.name, required this.resolve});

  Future<DidDereferenceResult> dereference(
    Did did, {
    HttpClient? client,
  }) async {
    final didResolutionResult = await resolve(did, client: client);

    if (didResolutionResult.hasError()) {
      return DidDereferenceResult.withError(
        didResolutionResult.didResolutionMetadata.error!,
      );
    }

    if (did.fragment == null) {
      return DidDereferenceResult(
        contentStream: didResolutionResult.didDocument as DidResource,
        contentMetadata: didResolutionResult.didDocumentMetadata,
      );
    }

    final resource = didResolutionResult.didDocument!.getResourceById(did.url);
    return resource != null
        ? DidDereferenceResult(contentStream: resource)
        : DidDereferenceResult.withError('notFound');
  }
}
