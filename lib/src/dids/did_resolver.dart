import 'package:tbdex/src/dids/did_method_resolver.dart';
import 'package:tbdex/src/dids/did_resolution_result.dart';
import 'package:tbdex/src/dids/did_uri.dart';

/// A resolver for Decentralized Identifiers (DIDs).
///
/// It allows for the resolution of a DID URI into a DID document by using
/// registered method resolvers.
class DidResolver {
  /// A map of method resolvers keyed by their names.
  Map<String, DidMethodResolver> methodResolvers = {};

  /// Constructs a [DidResolver] with a list of [DidMethodResolver]s.
  ///
  /// The method resolvers are used to handle resolution of specific DID methods.
  DidResolver({required List<DidMethodResolver> methodResolvers}) {
    for (final resolver in methodResolvers) {
      this.methodResolvers[resolver.name] = resolver;
    }
  }

  /// Resolves a DID URI into a [DidResolutionResult].
  ///
  /// Throws an [Exception] if no resolver is available for the given method.
  DidResolutionResult resolve(String didUri) {
    final parsedDidUri = DidUri.parse(didUri);
    final resolver = methodResolvers[parsedDidUri.method];

    if (resolver == null) {
      throw Exception("no resolver available for did:${parsedDidUri.method}");
    }

    return resolver.resolve(didUri);
  }
}
