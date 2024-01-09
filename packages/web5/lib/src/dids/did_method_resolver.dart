import 'package:web5/src/dids/dereference_result.dart';
import 'package:web5/src/dids/resolution_result.dart';

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

    if (!didUri.contains("#")) {
      return DidDereferenceResult(
        contentStream: didResolutionResult.didDocument,
        contentMetadata: didResolutionResult.didDocumentMetadata,
      );
    }

    final resource = didResolutionResult.didDocument!.getResourceById(didUri);
    if (resource != null) {
      return DidDereferenceResult(contentStream: resource);
    } else {
      return DidDereferenceResult.withError('notFound');
    }
  }
}
