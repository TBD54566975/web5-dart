import 'package:web5/src/dids/did.dart';
import 'package:web5/src/dids/did_core.dart';

/// Represents a method resolver for a specific DID method.
abstract class DidMethodResolver {
  /// The name of the DID method e.g. jwk, dht, web
  String get name;

  /// The function to resolve a DID URI using this method.
  Future<DidResolutionResult> resolve(Did did, {covariant dynamic options});

  Future<DidDereferenceResult> dereference(
    Did did, {
    dynamic options,
  }) async {
    final didResolutionResult = await resolve(did, options: options);

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
