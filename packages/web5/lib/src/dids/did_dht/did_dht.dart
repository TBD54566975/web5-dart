import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

import 'package:web5/src/dids.dart';
import 'package:web5/src/crypto.dart';
import 'package:web5/src/encoders/zbase.dart';
import 'package:web5/src/dids/did_dht/bep44.dart';
import 'package:web5/src/dids/did_dht/dns_packet.dart';
import 'package:web5/src/dids/did_dht/converters/did_document_converter.dart';

class DidDht {
  static const String methodName = 'dht';
  static const _defaultRelay = 'https://diddht.tbddev.org';

  static Future<BearerDid> create({
    KeyManager? keyManager,
    bool publish = false,
    String gatewayUri = _defaultRelay,
    List<String> alsoKnownAs = const [],
    List<String> controllers = const [],
    List<DidService> services = const [],
    List<DidDhtRegisteredDidType>? types,
    List<DidCreateVerificationMethod> verificationMethods = const [],
  }) async {
    keyManager ??= InMemoryKeyManager();

    final keyAlias = await keyManager.generatePrivateKey(AlgorithmId.ed25519);
    final identityKey = await keyManager.getPublicKey(keyAlias);

    final id = _computeIdentifier(identityKey: identityKey);
    final did = 'did:$methodName:$id';

    final identityVm = DidVerificationMethod(
      id: '0',
      type: 'JsonWebKey',
      controller: did,
      publicKeyJwk: identityKey,
    );

    final didDoc = DidDocument(
      id: did,
      alsoKnownAs: alsoKnownAs,
      controller: controllers.isEmpty ? [did] : controllers,
    );

    didDoc.addVerificationMethod(
      identityVm,
      purpose: [
        VerificationPurpose.authentication,
        VerificationPurpose.assertionMethod,
        VerificationPurpose.capabilityDelegation,
        VerificationPurpose.capabilityInvocation,
      ],
    );

    for (final vmOpts in verificationMethods) {
      final alias = await keyManager.generatePrivateKey(vmOpts.algorithm);
      final publicKey = await keyManager.getPublicKey(alias);

      // Use the given ID, the key's ID, or the key's thumbprint as the verification method ID.
      String methodId =
          vmOpts.id ?? publicKey.kid ?? publicKey.computeThumbprint();
      methodId = '$did#${methodId.split('#').last}';

      final vm = DidVerificationMethod(
        id: methodId,
        type: vmOpts.type,
        controller: vmOpts.controller,
        publicKeyJwk: publicKey,
      );
      didDoc.addVerificationMethod(vm, purpose: vmOpts.purposes);
    }

    for (final service in services) {
      didDoc.addService(service);
    }

    if (publish == true) {
      final dnsPacket = DidDocumentConverter.convertDidDocument(didDoc);
      sign(Uint8List data) async {
        return await keyManager!.sign(keyAlias, data);
      }

      final seq = DateTime.now().microsecondsSinceEpoch;
      final message = await Bep44Message.create(dnsPacket.encode(), seq, sign);

      final gatewayUrl = Uri.parse('$gatewayUri/$id');
      // TODO: add optional client
      final response = await http.Client().put(
        gatewayUrl,
        headers: {
          'Content-Type': 'application/octet-stream',
        },
        body: message,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to publish DID document. got: ${response.statusCode} ${response.body}',
        );
      }
    }

    return BearerDid(
      uri: did,
      keyManager: keyManager,
      document: didDoc,
      // metadata: DidDocumentMetadata(types: types),
    );
  }

  static Future<DidResolutionResult> resolve(
    Did did, {
    String relayUrl = _defaultRelay,
    http.Client? client,
  }) async {
    if (did.method != methodName) {
      return DidResolutionResult.withError(DidResolutionError.invalidDid);
    }

    final List<int> identityKey;
    try {
      identityKey = ZBase32.decode(did.id);
    } catch (e) {
      return DidResolutionResult.withError(DidResolutionError.invalidDid);
    }

    final parsedRelayUrl = Uri.parse(relayUrl);
    final resolutionUrl = parsedRelayUrl.replace(path: did.id);

    final httpClient = client ??= http.Client();
    final response = await httpClient.get(resolutionUrl);

    if (response.statusCode != 200) {
      throw Exception(
        'failed to resolve DID document: error code ${response.statusCode}, ${response.body}',
      );
    }

    final bep44Message = Bep44Message.verify(
      response.bodyBytes,
      Uint8List.fromList(identityKey),
    );

    try {
      final dnsPacket = DnsPacket.decode(bep44Message.v);
      final document = DidDocumentConverter.convertDnsPacket(did, dnsPacket);
      return DidResolutionResult(didDocument: document);
    } catch (e) {
      return DidResolutionResult.withError(DidResolutionError.invalidDid);
    }
  }

  static String _computeIdentifier({
    required Jwk identityKey,
  }) {
    // Convert the key from JWK format to a byte array.
    final Uint8List publicKeyBytes = Crypto.publicKeyToBytes(identityKey);

    return ZBase32.encode(publicKeyBytes);
  }
}

class DidDhtResolver extends DidMethodResolver {
  @override
  String get name => DidDht.methodName;

  @override
  Future<DidResolutionResult> resolve(Did did, {http.Client? options}) async =>
      DidDht.resolve(did, client: options);
}
