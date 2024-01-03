import 'dart:collection';
import 'dart:io';

import 'package:tbdex/src/dids/did.dart';
import 'package:tbdex/src/dids/did_document.dart';
import 'package:tbdex/src/dids/did_uri.dart';
import 'package:tbdex/src/dns_packet/packet.dart';
import 'package:tbdex/src/crypto/key_manager.dart';
import 'package:tbdex/src/dids/did_resolution_result.dart';
import 'package:tbdex/src/dns_packet/txt_data.dart';
import 'package:tbdex/src/dns_packet/type.dart';

final Set<String> txtEntryNames = {'vm', 'auth', 'asm', 'agm', 'inv', 'del'};

class DidDht implements Did {
  @override
  // TODO: implement keyManager
  KeyManager get keyManager => throw UnimplementedError();

  @override
  // TODO: implement uri
  String get uri => throw UnimplementedError();

  static const String methodName = 'dht';

  // static final resolver = DidMethodResolver(name: methodName, resolve: resolve);

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

    // TODO: verify signature
    final signatureBytes = bytes.sublist(0, 64);
    final seq = bytes.sublist(64, 72);

    final v = bytes.sublist(72);

    final dnsPacket = DnsPacket.decode(v);
    final Map<String, List<String>> txtMap = {};
    List<String>? rootRecord;

    for (final answer in dnsPacket.answers) {
      if (answer.type != DnsType.TXT) {
        continue;
      }

      final txtData = answer.data as DnsTxtData;
      txtMap[answer.name.value] = txtData.value;

      if (answer.name.value.startsWith('_did')) {
        rootRecord = txtData.value;
      }
    }

    if (rootRecord == null) {
      // TODO: figure out more appopriate resolution error to use.
      return DidResolutionResult.invalidDid();
    }

    final didDocument = DidDocument(id: didUri);
    for (final entry in rootRecord) {
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
        if (property == 'vm') {
          final vmProperties = txtMap['${value}_did.'];
          if (vmProperties == null) {
            continue;
          }
        }
      }
    }

    httpClient.close(force: false);

    return DidResolutionResult.invalidDid();
  }
}
