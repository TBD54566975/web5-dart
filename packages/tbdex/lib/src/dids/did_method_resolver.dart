import 'package:tbdex/src/dids/did_resolution_result.dart';

/// Represents a method resolver for a specific DID method.
class DidMethodResolver {
  /// The name of the DID method e.g. jwk, dht, web
  String name;

  /// The function to resolve a DID URI using this method.
  DidResolutionResult Function(String) resolve;

  /// Constructs a [DidMethodResolver] with a given [name] and [resolve] function.
  DidMethodResolver({required this.name, required this.resolve});
}
