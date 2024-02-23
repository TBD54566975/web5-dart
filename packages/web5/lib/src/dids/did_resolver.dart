import 'package:web5/src/dids/did.dart';
import 'package:web5/src/dids/did_core.dart';
import 'package:web5/src/dids/did_dht/did_dht.dart';
import 'package:web5/src/dids/did_jwk/did_jwk.dart';
import 'package:web5/src/dids/did_web/did_web.dart';
import 'package:web5/src/dids/did_method_resolver.dart';

/// A resolver for Decentralized Identifiers (DIDs).
///
/// It allows for the resolution of a DID URI into a DID document by using
/// registered method resolvers.
class DidResolver {
  /// A map of method resolvers keyed by their names.
  Map<String, DidMethodResolver> methodResolvers = {};

  factory DidResolver._default() {
    // Register resolvers that we provide out of the box
    return DidResolver(
      methodResolvers: [
        DidJwk.resolver,
        DidDht.resolver,
        DidWeb.resolver,
      ],
    );
  }

  // Static field to hold the instance
  static final DidResolver _instance = DidResolver._default();

  static Future<DidResolutionResult> resolve(String uri) {
    return _instance.resolveDid(uri);
  }

  static Future<DidDereferenceResult> dereference(String url) {
    return _instance.dereferenceDid(url);
  }

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
  Future<DidResolutionResult> resolveDid(String uri) {
    final Did did;
    try {
      did = Did.parse(uri);
    } catch (e) {
      return Future.value(DidResolutionResult.invalidDid());
    }

    final resolver = methodResolvers[did.method];

    if (resolver == null) {
      throw Exception('no resolver available for did:${did.method}');
    }

    return resolver.resolve(did);
  }

  /// Resolves a DID URI into a [DidResolutionResult].
  ///
  /// Throws an [Exception] if no resolver is available for the given method.
  Future<DidDereferenceResult> dereferenceDid(String url) {
    final did = Did.parse(url);
    final resolver = methodResolvers[did.method];

    if (resolver == null) {
      throw Exception('no resolver available for did:${did.method}');
    }

    return resolver.dereference(did);
  }
}
