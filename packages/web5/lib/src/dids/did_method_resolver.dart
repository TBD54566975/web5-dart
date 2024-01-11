import 'package:web5/src/dids/data_models.dart';

/// Represents a method resolver for a specific DID method.
class DidMethodResolver {
  /// The name of the DID method e.g. jwk, dht, web
  String name;

  /// The function to resolve a DID URI using this method.
  Future<DidResolutionResult> Function(String) resolve;

  /// Constructs a [DidMethodResolver] with a given [name] and [resolve] function.
  DidMethodResolver({required this.name, required this.resolve});

  Future<DidDereferenceResult> dereference(String didUri) async {
    final didResolutionResult = await resolve(didUri);

    if (didResolutionResult.hasError()) {
      return DidDereferenceResult.withError(
        didResolutionResult.didResolutionMetadata.error!,
      );
    }

    if (!didUri.contains('#')) {
      return DidDereferenceResult(
        contentStream: didResolutionResult.didDocument as DidResource,
        contentMetadata: didResolutionResult.didDocumentMetadata,
      );
    }

    final resource = didResolutionResult.didDocument!.getResourceById(didUri);
    return resource != null
        ? DidDereferenceResult(contentStream: resource)
        : DidDereferenceResult.withError('notFound');
  }
}
