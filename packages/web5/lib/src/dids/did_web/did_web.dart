import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web5/src/crypto.dart';
import 'package:web5/src/dids/bearer_did.dart';
import 'package:web5/src/dids/did.dart';
import 'package:web5/src/dids/did_core.dart';
import 'package:web5/src/dids/did_method_resolver.dart';

class DidWeb {
  static const String methodName = 'web';

  static Future<BearerDid> create({
    required String url,
    AlgorithmId? algorithm,
    KeyManager? keyManager,
    List<String>? alsoKnownAs,
    List<String>? controllers,
    List<DidService>? services,
    List<DidCreateVerificationMethod>? verificationMethods,
    DidDocumentMetadata? metadata,
  }) async {
    algorithm ??= AlgorithmId.ed25519;
    keyManager ??= InMemoryKeyManager();

    final parsed = Uri.tryParse(url);
    if (parsed == null) throw 'Unable to parse url $url';
    final String didId =
        'did:web:${parsed.host}${parsed.pathSegments.join(':')}';

    final DidDocument doc = DidDocument(
      id: didId,
      alsoKnownAs: alsoKnownAs,
      controller: controllers ?? [didId],
    );

    final List<DidCreateVerificationMethod> defaultMethods = [
      DidCreateVerificationMethod(
        algorithm: algorithm,
        id: '0',
        type: 'JsonWebKey',
        controller: didId,
        purposes: [
          VerificationPurpose.authentication,
          VerificationPurpose.assertionMethod,
          VerificationPurpose.capabilityDelegation,
          VerificationPurpose.capabilityInvocation,
        ],
      ),
    ];

    final List<DidCreateVerificationMethod> methodsToAdd =
        verificationMethods ?? defaultMethods;

    for (final DidCreateVerificationMethod vm in methodsToAdd) {
      final String alias = await keyManager.generatePrivateKey(vm.algorithm);
      final Jwk publicKey = await keyManager.getPublicKey(alias);

      final String methodId = '$didId#${vm.id}';
      doc.addVerificationMethod(
        DidVerificationMethod(
          id: methodId,
          type: vm.type,
          controller: vm.controller,
          publicKeyJwk: publicKey,
        ),
      );

      for (final VerificationPurpose purpose in vm.purposes) {
        doc.addVerificationPurpose(purpose, methodId);
      }
    }

    for (final DidService service in (services ?? [])) {
      doc.addService(service);
    }

    return BearerDid(
      uri: didId,
      keyManager: keyManager,
      document: doc,
      metadata: metadata ?? DidDocumentMetadata(),
    );
  }

  static Future<DidResolutionResult> resolve(
    Did did, {
    http.Client? client,
  }) async {
    if (did.method != methodName) {
      return DidResolutionResult.withError(DidResolutionError.invalidDid);
    }

    var resolutionUrl = Uri.decodeFull(did.id.replaceAll(':', '/'));
    if (resolutionUrl.contains('localhost') ||
        DidWebResolver._containsIPv4(resolutionUrl)) {
      resolutionUrl = 'http://$resolutionUrl';
    } else {
      resolutionUrl = 'https://$resolutionUrl';
    }

    var didUri = Uri.tryParse(resolutionUrl);

    if (didUri == null) throw 'Unable to parse DID document Url $resolutionUrl';

    // If none was specified, use the default path.
    if (didUri.path.isEmpty) didUri = didUri.replace(path: '/.well-known');
    didUri = didUri.replace(pathSegments: [...didUri.pathSegments, 'did.json']);

    final httpClient = client ??= http.Client();
    final response = await httpClient.get(didUri);

    if (response.statusCode != 200) {
      return DidResolutionResult.withError(DidResolutionError.notFound);
    }

    final jsonParsed = json.decode(response.body);
    final doc = DidDocument.fromJson(jsonParsed);

    return DidResolutionResult(didDocument: doc);
  }
}

class DidWebResolver extends DidMethodResolver {
  @override
  String get name => DidWeb.methodName;

  /// checks whether a string contains an ipv4 address
  ///! Note: this is only temporarily here while we test using did:web:<ip_addr>
  static bool _containsIPv4(String str) {
    final ipv4Regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}');

    return ipv4Regex.hasMatch(str);
  }

  @override
  Future<DidResolutionResult> resolve(Did did, {http.Client? options}) =>
      DidWeb.resolve(did, client: options);
}
