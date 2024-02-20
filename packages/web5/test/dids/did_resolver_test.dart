import 'package:test/test.dart';
import 'package:web5/src/dids/did_resolver.dart';

void main() {
  group('DidResolver', () {
    test('should resolve with error if did is not valid', () async {
      final resolutionResult = await DidResolver.resolve('hi');

      expect(resolutionResult.didDocument, isNull);
      expect(
        resolutionResult.didResolutionMetadata.error,
        equals('invalidDid'),
      );
    });
  });
}
