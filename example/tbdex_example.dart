import 'package:tbdex/tbdex.dart';

void main() async {
  final keyManager = InMemoryKeyManager();
  var did = await DidJwk.create(keyManager: keyManager);
  print(did.uri);
}
