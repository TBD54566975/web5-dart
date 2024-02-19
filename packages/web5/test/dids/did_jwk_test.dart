import 'package:web5/web5.dart';
import 'package:test/test.dart';

void main() {
  group('DidJwk', () {
    test('should create a valid DID', () async {
      final keyManager = InMemoryKeyManager();
      final did = await DidJwk.create(keyManager: keyManager);

      expect(did.uri, startsWith('did:jwk:'));
    });

    // test('should resolve with error if kaka DID', () async {
    //   final resolutionResult = await DidJwk.resolve('hi');

    //   expect(resolutionResult.didDocument, isNull);
    //   expect(
    //     resolutionResult.didResolutionMetadata.error,
    //     equals('invalidDid'),
    //   );
    // });

    test('should resolve with error if not did:jwk', () async {
      final did =
          Did.parse('did:key:z6MkpTHR8VNsBxYAAWHut2Geadd9jSwuBV8xRoAnwWsdvktH');
      final resolutionResult = await DidJwk.resolve(did);

      expect(resolutionResult.didDocument, isNull);
      expect(
        resolutionResult.didResolutionMetadata.error,
        equals('invalidDid'),
      );
    });

    test('should resolve with error if id is not valid base64url', () async {
      final did = Did.parse('did:jwk:abc_123');
      final resolutionResult = await DidJwk.resolve(did);

      expect(resolutionResult.didDocument, isNull);
      expect(
        resolutionResult.didResolutionMetadata.error,
        equals('invalidDid'),
      );
    });

    test('should resolve with didDocument if legit', () async {
      final did = Did.parse(
          'did:jwk:eyJraWQiOiJ1cm46aWV0ZjpwYXJhbXM6b2F1dGg6andrLXRodW1icHJpbnQ6c2hhLTI1NjpGZk1iek9qTW1RNGVmVDZrdndUSUpqZWxUcWpsMHhqRUlXUTJxb2JzUk1NIiwia3R5IjoiT0tQIiwiY3J2IjoiRWQyNTUxOSIsImFsZyI6IkVkRFNBIiwieCI6IkFOUmpIX3p4Y0tCeHNqUlBVdHpSYnA3RlNWTEtKWFE5QVBYOU1QMWo3azQifQ');
      final resolutionResult = await DidJwk.resolve(did);

      expect(resolutionResult.didDocument, isNotNull);
      expect(resolutionResult.didResolutionMetadata.isEmpty(), isTrue);
    });
  });
}
