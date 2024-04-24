import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:web5/src/crypto.dart';
import 'package:web5/src/dids.dart';
import 'package:web5/src/dids/did_dht/bep44.dart';
import 'package:web5/src/dids/did_dht/registered_types.dart';
import 'package:web5/src/dids/did_dht/converters/did_document_converter.dart';
import 'package:web5/src/encoders/zbase.dart';

class DidDht {
  static const String methodName = 'dht';
  static const _defaultRelay = 'https://diddht.tbddev.org';

  static final resolver = DidMethodResolver(name: methodName, resolve: resolve);

  // TODO: allow for custom http client
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

      final pkarrUrl = Uri.parse('$gatewayUri/$id');
      final request = await HttpClient().putUrl(pkarrUrl);

      request.headers.contentType = ContentType.binary;
      request.add(message);

      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        final body = await response.transform(utf8.decoder).join();
        throw Exception(
          'Failed to publish DID document. got: ${response.statusCode} $body',
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
    HttpClient? client,
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

    final httpClient = client ??= HttpClient();
    final request = await httpClient.getUrl(resolutionUrl);
    final response = await request.close();

    final List<int> bytes = [];
    await for (var byteList in response) {
      bytes.addAll(byteList);
    }

    httpClient.close(force: false);

    final bep44Message = Bep44Message.verify(
      Uint8List.fromList(bytes),
      Uint8List.fromList(identityKey),
    );

    try {
      final document =
          DidDocumentConverter.convertDnsPacket(did.uri, bep44Message.v);
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
