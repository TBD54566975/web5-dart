import 'dart:convert';

import 'package:web5/web5.dart';

void main() async {
  final keyManager = InMemoryKeyManager();

  final did = await DidJwk.create(keyManager: keyManager);
  print(did.uri);

  final didResolutionResult = DidJwk.resolve(did.uri);
  print(jsonEncode(didResolutionResult));
}
