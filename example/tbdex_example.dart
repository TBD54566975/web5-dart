import 'dart:convert';

import 'package:tbdex/src/dids/did_dht.dart';

void main() async {
  // final keyManager = InMemoryKeyManager();

  // final did = await DidJwk.create(keyManager: keyManager);
  // print(did.uri);

  // final didResolutionResult = DidJwk.resolve(did.uri);
  // print(jsonEncode(didResolutionResult));

  // final zb32 = base32.encodeString('hello', encoding: Encoding.zbase32);
  // print(zb32);

  final resolutionResult = await DidDht.resolve(
    "did:dht:5nzzr8izm434fukrjiiq164jb9tdctyhdmt5pnf7zywbpw9itkzo",
  );

  final jenc = JsonEncoder.withIndent('  ');
  print(jenc.convert(resolutionResult.toJson()));
}
