// TODO make txtEntryNames a static value in each service class

import 'dart:io';
import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/bep44.dart';
import 'package:web5/src/dids/did_dht/deed_dht_type.dart';
import 'package:web5/src/dids/did_dht/dns/packet.dart';
import 'package:web5/src/dids/did_dht/document_packet.dart';
import 'package:web5/src/encoders/zbase.dart';
import 'package:web5/web5.dart';

class DeedDht {
  static const String methodName = 'dht';
  static const _defaultRelay = 'https://diddht.tbddev.org';

  // static final resolver = DidMethodResolver(name: methodName, resolve: resolve);

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
      verificationMethod: [identityVm],
    );

    final identityVmPurposes = [
      VerificationPurpose.authentication,
      VerificationPurpose.assertionMethod,
      VerificationPurpose.capabilityDelegation,
      VerificationPurpose.capabilityInvocation,
    ];

    for (final purp in identityVmPurposes) {
      didDoc.addVerificationPurpose(purp, identityVm.id);
    }

    for (final DidCreateVerificationMethod vm in verificationMethods) {
      final alias = await keyManager.generatePrivateKey(vm.algorithm);
      final publicKey = await keyManager.getPublicKey(alias);

      // Use the given ID, the key's ID, or the key's thumbprint as the verification method ID.
      String methodId = vm.id ?? publicKey.kid ?? publicKey.computeThumbprint();
      methodId = '$didUri#${methodId.split('#').last}';

      didDoc.addVerificationMethod(
        DidVerificationMethod(
          id: methodId,
          type: vm.type,
          controller: vm.controller,
          publicKeyJwk: publicKey,
        ),
      );

      for (final purpose in vm.purposes) {
        didDoc.addVerificationPurpose(purpose, methodId);
      }
    }

    for (final service in services) {
      didDoc.addService(service);
    }

    if (publish == true) {
      final dnsPacket = DocumentPacket.toPacket(didDoc);

      sign(Uint8List data) async {
        return await keyManager!.sign(keyAlias, data);
      }

      // TODO: figure out proper seq number
      final message = Bep44Message.create(dnsPacket, 0, identityKey, sign);

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

    final dnsPacket = Packet.codec.decode(Uint8List.fromList(bytes));
    final didDocument = DocumentPacket.toDidDocument(dnsPacket.value);

    // TODO: add verification methods and purposes to did doc

    return DidResolutionResult(didDocument: didDocument);
  }

  static String _computeIdentifier({
    required Jwk identityKey,
  }) {
    // Convert the key from JWK format to a byte array.
    final Uint8List publicKeyBytes = Crypto.publicKeyToBytes(identityKey);

    final String identifier = ZBase32.encode(publicKeyBytes);
    return 'did:${DidDht.methodName}:$identifier';
  }
}
