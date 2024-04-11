import 'dart:convert';
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:web5/web5.dart';

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpRequest extends Mock implements HttpClientRequest {}

class MockHttpResponse extends Mock implements HttpClientResponse {}

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
        'did:dht:5nzzr8izm434fukrjiiq164jb9tdctyhdmt5pnf7zywbpw9itkzo',
      );
      final resolutionResult = await DidDht.resolve(did);

      expect(resolutionResult.didResolutionMetadata.isEmpty(), isTrue);
      expect(resolutionResult.didDocument, isNotNull);
    });

    test('IN PROGRESS: should resolve with didDocument', () async {
      when(() => response.statusCode).thenReturn(200);
      when(() => request.close()).thenAnswer((_) async => response);
      when(
        () => mockClient.getUrl(
          Uri.parse(
            'https://diddht.tbddev.org/74hg1efatndi8enx3e4z6c4u8ieh1xfkyay4ntg4dg1w6risu35y',
          ),
        ),
      ).thenAnswer((_) async => request);

      // creating a temp did to help stub a mock stream for the response
      final tempDid = await DidDht.create(keyManager: InMemoryKeyManager());
      // what do we want the response to be? prob not this did doc...
      final docJson = jsonEncode(tempDid.document);
      // convert the document to bytes
      final byteData = utf8.encode(docJson);
      // create a stream from the bytes
      final mockStream = Stream<List<int>>.fromIterable([byteData]);
      // for when we listen to the response data?
      when(
        () => response.listen(
          any(),
          onError: any(named: 'onError'),
          onDone: any(named: 'onDone'),
          cancelOnError: any(named: 'cancelOnError'),
        ),
      ).thenAnswer((invocation) {
        return mockStream.listen(invocation.positionalArguments[0],
            onError: invocation.namedArguments[#onError],
            onDone: invocation.namedArguments[#onDone],
            cancelOnError: invocation.namedArguments[#cancelOnError]);
      });

      // this is where the test starts
      final did = Did.parse(
        'did:dht:74hg1efatndi8enx3e4z6c4u8ieh1xfkyay4ntg4dg1w6risu35y',
      );
      final resolutionResult = await DidDht.resolve(did, client: mockClient);

      expect(resolutionResult.didResolutionMetadata.isEmpty(), isTrue);
      expect(resolutionResult.didDocument, isNotNull);
    });
  });
}
