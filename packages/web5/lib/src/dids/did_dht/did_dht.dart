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

    final String keyAlias =
        await keyManager.generatePrivateKey(AlgorithmId.ed25519);

    final Jwk identityKey = await keyManager.getPublicKey(keyAlias);
    final String didUri = _computeIdentifier(identityKey: identityKey);

    final identityVm = DidVerificationMethod(
      id: '0',
      type: 'JsonWebKey',
      controller: didUri,
    );

    final didDoc = DidDocument(
      id: didUri,
      alsoKnownAs: alsoKnownAs,
      controller: controllers.isEmpty ? [didUri] : controllers,
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
      methodId = '$didUri#${methodId.split('#').last}';

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
      final message = Bep44Message.create(dnsPacket, seq, identityKey, sign);

      // TODO: publish message to DHT
    }

    return BearerDid(
      uri: didUri,
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

    // 72 is the minimal bytes length of a BEP44 message. this should be handled in bep44 decode
    // if (bytes.length < 72) {
    //   return DidResolutionResult.withError(DidResolutionError.invalidDid);
    // }
    // final v = bytes.sublist(72);

    //! This is a placeholder
    return DidResolutionResult.withError(DidResolutionError.invalidDid);

    // return DidResolutionResult(didDocument: didDocument);
  }

  static String _computeIdentifier({
    required Jwk identityKey,
  }) {
    // Convert the key from JWK format to a byte array.
    final Uint8List publicKeyBytes = Crypto.publicKeyToBytes(identityKey);

    final String identifier = ZBase32.encode(publicKeyBytes);
    return 'did:$methodName:$identifier';
  }
}
