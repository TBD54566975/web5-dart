import 'package:tbdex/tbdex.dart';
import 'package:test/test.dart';

void main() {
  group('TBDex', () {
    test('should create a valid DID', () async {
      final keyManager = InMemoryKeyManager();
      final did = await DidJwk.create(keyManager: keyManager);

      expect(did.uri, startsWith('did:jwk:'));
    });
  });
}
