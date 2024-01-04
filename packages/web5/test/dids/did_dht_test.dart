import 'package:web5/src/dids/did_dht.dart';
import 'package:test/test.dart';

void main() {
  group('DidDht', () {
    test('should resolve with error if dookie DID', () async {
      final resolutionResult = await DidDht.resolve('hi');

      expect(resolutionResult.didDocument, isNull);
      expect(
        resolutionResult.didResolutionMetadata.error,
        equals('invalidDid'),
      );
    });

    test('should resolve with error if not did:dht', () async {
      final resolutionResult = await DidDht.resolve(
        'did:key:z6MkpTHR8VNsBxYAAWHut2Geadd9jSwuBV8xRoAnwWsdvktH',
      );

      expect(resolutionResult.didDocument, isNull);
      expect(
        resolutionResult.didResolutionMetadata.error,
        equals('invalidDid'),
      );
    });

    test('should resolve with error if id is not valid zbase32', () async {
      final resolutionResult = await DidDht.resolve('did:dht:!!!');

      expect(resolutionResult.didDocument, isNull);
      expect(
        resolutionResult.didResolutionMetadata.error,
        equals('invalidDid'),
      );
    });

    test('should resolve with didDocument if legit', () async {
      final resolutionResult = await DidDht.resolve(
        'did:dht:5nzzr8izm434fukrjiiq164jb9tdctyhdmt5pnf7zywbpw9itkzo',
      );

      expect(resolutionResult.didDocument, isNotNull);
      expect(resolutionResult.didResolutionMetadata.isEmpty(), isTrue);
    });
  });
}
