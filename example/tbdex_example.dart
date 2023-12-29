import 'dart:convert';

import 'package:tbdex/src/crypto/secp256k1.dart';
import 'package:tbdex/src/dids/did.dart';
import 'package:tbdex/tbdex.dart';

void main() async {
  final keyManager = InMemoryKeyManager();
  final did = await DidJwk.create(keyManager: keyManager);
  print(did.uri);

  // final didMatcher = RegExp(
  //   r'^did:([a-z0-9]+):((?:(?:[a-zA-Z0-9._-]|(?:%[0-9a-fA-F]{2}))*:)*((?:[a-zA-Z0-9._-]|(?:%[0-9a-fA-F]{2}))+))((;[a-zA-Z0-9_.:%-]+=[a-zA-Z0-9_.:%-]*)*)(\/[^#?]*)?([?][^#]*)?(#.*)?$',
  // );

  // final sections = didMatcher.firstMatch('did:jwk:abcd123#yoyo');

  final didResolutionResult = DidJwk.resolve(did.uri);

  print(jsonEncode(didResolutionResult));
}
