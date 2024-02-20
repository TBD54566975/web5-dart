import 'package:web5/src/dids/did.dart';
import 'package:web5/src/dids/did_dht/did_dht.dart';
import 'package:test/test.dart';

void main() {
  group('DidDht', () {
    test('should resolve with error if not did:dht', () async {
      final did =
          Did.parse('did:key:z6MkpTHR8VNsBxYAAWHut2Geadd9jSwuBV8xRoAnwWsdvktH');
      final resolutionResult = await DidDht.resolve(did);

      expect(resolutionResult.didDocument, isNull);
      expect(
        resolutionResult.didResolutionMetadata.error,
        equals('invalidDid'),
      );
    });

    test('should resolve with error if id is not valid zbase32', () async {
      final did = Did.parse('did:dht:abc_123');
      final resolutionResult = await DidDht.resolve(did);

      expect(resolutionResult.didDocument, isNull);
      expect(
        resolutionResult.didResolutionMetadata.error,
        equals('invalidDid'),
      );
    });

    test('should resolve with didDocument if legit', () async {
      final did = Did.parse(
        'did:dht:5nzzr8izm434fukrjiiq164jb9tdctyhdmt5pnf7zywbpw9itkzo',
      );
      final resolutionResult = await DidDht.resolve(did);

      expect(resolutionResult.didResolutionMetadata.isEmpty(), isTrue);
      expect(resolutionResult.didDocument, isNotNull);
    });
  });
}
