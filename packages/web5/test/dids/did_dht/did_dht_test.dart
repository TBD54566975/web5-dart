import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:web5/web5.dart';

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpRequest extends Mock implements HttpClientRequest {}

class MockHttpResponse extends Mock implements HttpClientResponse {}

const validDidDhtDocument =
    '''{id: did:dht:74hg1efatndi8enx3e4z6c4u8ieh1xfkyay4ntg4dg1w6risu35y, verificationMethod: [{id: 0, type: JsonWebKey2020, controller: did:dht:74hg1efatndi8enx3e4z6c4u8ieh1xfkyay4ntg4dg1w6risu35y, publicKeyJwk: {kty: OKP, alg: EdDSA, kid: a6tCQvXJQIZQZs_A126CcOT7PuP6R3yADH6DJLr1Zkg, crv: Ed25519, x: 7rhpILiIh1OgT8o1fzNTPVHJPKoGAaFE2hmlTxK2nnY}}], service: [{id: kyc-widget, type: kyc-widget, serviceEndpoint: http://localhost:5173}, {id: pfi, type: PFI, serviceEndpoint: http://localhost:8892/ingress/pfi}], assertionMethod: [0], authentication: [0], capabilityDelegation: [0], capabilityInvocation: [0]}''';

void main() {
  final MockHttpClient mockClient = MockHttpClient();
  final MockHttpRequest request = MockHttpRequest();
  final MockHttpResponse response = MockHttpResponse();

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    reset(mockClient);
    reset(request);
    reset(response);
  });

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
        'did:dht:3whftgpbdjihx9ze9tdn575zqzm4qwccetnf1ybiibuzad7rrmyy',
      );
      final resolutionResult = await DidDht.resolve(did);

      expect(resolutionResult.didResolutionMetadata.isEmpty(), isTrue);
      expect(resolutionResult.didDocument, isNotNull);
    });
  });
}
