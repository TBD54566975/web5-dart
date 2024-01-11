import 'dart:convert';
import 'dart:io';

import 'package:web5/src/crypto.dart';
import 'package:web5/src/dids/did.dart';
import 'package:web5/src/extensions.dart';
import 'package:web5/src/dids/did_uri.dart';
import 'package:web5/src/dids/data_models.dart';
import 'package:web5/src/dids/did_dht/dns_packet.dart';
import 'package:web5/src/dids/did_method_resolver.dart';

final Set<String> txtEntryNames = {'vm', 'auth', 'asm', 'agm', 'inv', 'del'};
final _base64UrlCodec = Base64Codec.urlSafe();
final _base64UrlDecoder = _base64UrlCodec.decoder;

class DidDht implements Did {
  @override
  // TODO: implement keyManager
  KeyManager get keyManager => throw UnimplementedError();

  @override
  // TODO: implement uri
  String get uri => throw UnimplementedError();

  static const String methodName = 'dht';

  static final resolver = DidMethodResolver(name: methodName, resolve: resolve);

  static Future<DidResolutionResult> resolve(
    String didUri, {
    String relayUrl = 'https://diddht.tbddev.org',
  }) async {
    final DidUri parsedDidUri;

    try {
      parsedDidUri = DidUri.parse(didUri);
    } on Exception {
      return DidResolutionResult.invalidDid();
    }

    if (parsedDidUri.method != methodName) {
      return DidResolutionResult.invalidDid();
    }

    final parsedRelayUrl = Uri.parse(relayUrl);
    final resolutionUrl = parsedRelayUrl.replace(path: parsedDidUri.id);

    final httpClient = HttpClient();
    final request = await httpClient.getUrl(resolutionUrl);
    final response = await request.close();

    final List<int> bytes = [];
    // Listening for response data
    await for (var byteList in response) {
      bytes.addAll(byteList);
    }

    httpClient.close(force: false);

    // TODO: verify signature
    // final signatureBytes = bytes.sublist(0, 64);
    // final seq = bytes.sublist(64, 72);

    final v = bytes.sublist(72);

    final dnsPacket = DnsPacket.decode(v);
    final Map<String, List<String>> txtMap = {};
    List<String>? rootRecord;

    for (final answer in dnsPacket.answers) {
      if (answer.type != DnsType.TXT) {
        continue;
      }

      final txtData = answer.data as DnsTxtData;

      if (answer.name.value.startsWith('_did')) {
        rootRecord = txtData.value;
        continue;
      }

      txtMap[answer.name.value] = txtData.value;
    }

    if (rootRecord == null) {
      // TODO: figure out more appopriate resolution error to use.
      return DidResolutionResult.invalidDid();
    }

    final Map<String, List<String>> relationshipsMap = {};
    for (final entry in rootRecord[0].split(';')) {
      final splitEntry = entry.split('=');

      if (splitEntry.length != 2) {
        // TODO: figure out more appopriate resolution error to use.
        return DidResolutionResult.invalidDid();
      }

      final [property, values] = splitEntry;
      final splitValues = values.split(',');

      if (!txtEntryNames.contains(property)) {
        continue;
      }

      for (final value in splitValues) {
        relationshipsMap[value] ??= [];
        relationshipsMap[value]!.add(value);
      }
    }

    final didDocument = DidDocument(id: didUri);
    for (final property in txtMap.entries) {
      final values = property.value[0].split(',');
      final valueMap = {};

      for (var value in values) {
        final [k, v] = value.split('=');
        valueMap[k] = v;
      }

      if (property.key.startsWith('_k')) {
        Dsa? dsa;
        switch (valueMap['t']) {
          case '0':
            dsa = Ed25519();
            break;
          case '1':
            dsa = Secp256k1();
            break;
          default:
            break;
        }

        if (dsa == null) {
          throw Exception('idk rn');
        }

        final publicKeyBytes =
            _base64UrlDecoder.convertNoPadding(valueMap['k']);
        final publicKeyJwk = dsa.bytesToPublicKey(publicKeyBytes);
        final verificationMethod = DidVerificationMethod(
          controller: didUri,
          id: valueMap['id'],
          type: 'JsonWebKey2020',
          publicKeyJwk: publicKeyJwk,
        );

        didDocument.addVerificationMethod(verificationMethod);
        final entryId = property.key.substring(1).split('.')[0];
        final relationships = relationshipsMap[entryId];

        if (relationships == null) {
          continue;
        }

        for (final relationship in relationships) {
          VerificationRelationship? vr;
          if (relationship == 'auth') {
            vr = VerificationRelationship.authentication;
          } else if (relationship == 'asm') {
            vr = VerificationRelationship.assertionMethod;
          } else if (relationship == 'agm') {
            vr = VerificationRelationship.keyAgreement;
          } else if (relationship == 'inv') {
            vr = VerificationRelationship.capabilityInvocation;
          } else if (relationship == 'del') {
            vr = VerificationRelationship.capabilityDelegation;
          }

          if (vr != null) {
            didDocument.addVerificationRelationship(vr, verificationMethod.id);
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
}
