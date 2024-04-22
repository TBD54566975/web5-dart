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

    // TODO: pass in bytes to bep44 verify to get decoded bep44 message

    // 72 is the minimal bytes length of a BEP44 message. this should be handled in bep44 decode
    if (bytes.length < 72) {
      return DidResolutionResult.withError(DidResolutionError.invalidDid);
    }
    final v = bytes.sublist(72);

    // assume that bep44 decode will return a dns packet
    final dnsPacket = Packet.codec.decode(Uint8List.fromList(v)).value;
    final didDocument = DocumentPacket.toDidDocument(dnsPacket);

    // TODO: is this how we want to use document packet?
    final docPack = DocumentPacket();
    docPack.populateTxtMap(dnsPacket.answers);

    if (docPack.rootRecord == null) {
      // TODO: figure out more appopriate resolution error to use.
      return DidResolutionResult.withError(DidResolutionError.invalidDid);
    }

    docPack.populateRelationshipsMap(docPack.rootRecord!);

    for (final property in docPack.txtMap.entries) {
      final values = property.value[0].split(',');
      final valueMap = {};

      for (var value in values) {
        final [k, v] = value.split('=');
        valueMap[k] = v;
      }

      if (property.key.startsWith('_k')) {
        AlgorithmId algId;
        switch (valueMap['t']) {
          case '0':
            algId = AlgorithmId.ed25519;
            break;
          case '1':
            algId = AlgorithmId.secp256k1;
            break;
          default:
            throw Exception('unsupported algorithm type: ${valueMap['t']}');
        }

        final publicKeyBytes = Base64Url.decode(valueMap['k']);
        final publicKeyJwk = Crypto.bytesToPublicKey(algId, publicKeyBytes);
        final verificationMethod = DidVerificationMethod(
          controller: did.uri,
          id: valueMap['id'],
          type: 'JsonWebKey2020',
          publicKeyJwk: publicKeyJwk,
        );

        didDocument.addVerificationMethod(verificationMethod);
        final entryId = property.key.substring(1).split('.')[0];
        final relationships = docPack.relationshipsMap[entryId];

        if (relationships == null) {
          continue;
        }

        for (final relationship in relationships) {
          VerificationPurpose? vr;
          if (relationship == 'auth') {
            vr = VerificationPurpose.authentication;
          } else if (relationship == 'asm') {
            vr = VerificationPurpose.assertionMethod;
          } else if (relationship == 'agm') {
            vr = VerificationPurpose.keyAgreement;
          } else if (relationship == 'inv') {
            vr = VerificationPurpose.capabilityInvocation;
          } else if (relationship == 'del') {
            vr = VerificationPurpose.capabilityDelegation;
          }

          if (vr != null) {
            didDocument.addVerificationPurpose(vr, verificationMethod.id);
          }
        }
      } else if (property.key.startsWith('_s')) {
        final service = DidService(
          id: valueMap['id'],
          type: valueMap['t'],
          serviceEndpoint: valueMap['uri'],
        );

        didDocument.addService(service);
      }
    }

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
