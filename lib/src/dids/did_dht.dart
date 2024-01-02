import 'dart:io';

import 'package:tbdex/src/dids/did.dart';
import 'package:tbdex/src/dids/did_uri.dart';
import 'package:tbdex/src/dns_packet/packet.dart';
import 'package:tbdex/src/crypto/key_manager.dart';
import 'package:tbdex/src/dids/did_resolution_result.dart';
import 'package:tbdex/src/dns_packet/txt_data.dart';
import 'package:tbdex/src/dns_packet/type.dart';

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

    final signatureBytes = bytes.sublist(0, 64);
    final seq = bytes.sublist(64, 72);
    final v = bytes.sublist(72);

    final dnsPacket = DnsPacket.decode(v);
    for (final answer in dnsPacket.answers) {
      print("${answer.type} ${answer.name.name}");

      if (answer.type == DnsType.TXT) {
        final txtData = answer.data as DnsTxtData;
        print("txt data: ${txtData.data}");
      }
    }

    httpClient.close(force: false);

    return DidResolutionResult.invalidDid();
  }
}
