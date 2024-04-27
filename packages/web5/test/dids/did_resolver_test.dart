import 'dart:convert';

import 'package:test/test.dart';
import 'package:web5/src/dids.dart';
import 'package:web5/src/dids/did_dht/converters.dart';

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

    test('should resolve with error if did method is not supported', () async {
      expect(
        () async {
          await DidResolver.resolve('did:hi:123');
        },
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            '',
            'Exception: no resolver available for did:hi',
          ),
        ),
      );
    });

    test('should resolve with valid did:dht', () async {
      final bearerDid = await DidDht.create(publish: true);
      final did = Did.parse(bearerDid.uri);

      final x = await DidDht.resolve(did);
      expect(x.didDocument, isNotNull);
    });
  });
}
