import 'dart:convert';
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:web5/src/dids/did.dart';
import 'package:web5/src/dids/did_core/did_resolution_result.dart';
import 'package:web5/src/dids/did_web/did_web.dart';

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpRequest extends Mock implements HttpClientRequest {}

class MockHttpResponse extends Mock implements HttpClientResponse {}

const validDidWebDocument = '''{
        "id": "did:web:www.linkedin.com",
        "@context": [
          "https://www.w3.org/ns/did/v1",
          {
            "@base": "did:web:www.linkedin.com"
          }
        ],
        "service": [
          {
            "id": "#linkeddomains",
            "type": "LinkedDomains",
            "serviceEndpoint": {
              "origins": [
                "https://www.linkedin.com/"
              ]
            }
          },
          {
            "id": "#hub",
            "type": "IdentityHub",
            "serviceEndpoint": {
              "instances": [
                "https://hub.did.msidentity.com/v1.0/658728e7-1632-412a-9815-fe53f53ec58b"
              ]
            }
          }
        ],
        "verificationMethod": [
          {
            "id": "#074cfbf193f046bcba5841ac4751e91bvcSigningKey-46682",
            "controller": "did:web:www.linkedin.com",
            "type": "EcdsaSecp256k1VerificationKey2019",
            "publicKeyJwk": {
              "crv": "secp256k1",
              "kty": "EC",
              "x": "NHIQivVR0HX7c0flpxgWQ7vRtbWDvr0UPN1nJ--0lyU",
              "y": "hYiIldgLRShym7vzflFrEkg6NYkayUHkDpV0RMjUEYE"
            }
          }
        ],
        "authentication": [
          "#074cfbf193f046bcba5841ac4751e91bvcSigningKey-46682"
        ],
        "assertionMethod": [
          "#074cfbf193f046bcba5841ac4751e91bvcSigningKey-46682"
        ]
      }''';

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

  group('DidWeb', () {
    // test('should return invalid did with bad data', () async {
    //   final result = await DidWeb.resolve('bogus');
    //   expect(result, DidResolutionResult.invalidDid());
    // });

    test('should return invalid did with wrong method', () async {
      final did = Did.parse('did:bad:www.linkedin.com');
      final result = await DidWeb.resolve(did);
      expect(result, DidResolutionResult.invalidDid());
    });

    test('should return invalid did with failed http request', () async {
      when(() => response.statusCode).thenReturn(400);
      when(() => request.close()).thenAnswer((_) async => response);
      when(() => mockClient.getUrl(any())).thenAnswer((_) async => request);

      final did = Did.parse('did:web:www.linkedin.com');
      final result = await DidWeb.resolve(did, client: mockClient);
      expect(result, DidResolutionResult.invalidDid());
    });

    test('should resolve successfully', () async {
      when(() => response.statusCode).thenReturn(200);
      when(() => response.transform(utf8.decoder))
          .thenAnswer((_) => Stream.value(validDidWebDocument));
      when(() => request.close()).thenAnswer((_) async => response);
      when(
        () => mockClient.getUrl(
          Uri.parse('https://www.linkedin.com/.well-known/did.json'),
        ),
      ).thenAnswer((_) async => request);

      final did = Did.parse('did:web:www.linkedin.com');
      final result = await DidWeb.resolve(did, client: mockClient);

      expect(result.didDocument, isNotNull);
      expect('did:web:www.linkedin.com', result.didDocument!.id);

      verify(
        () => mockClient
            .getUrl(Uri.parse('https://www.linkedin.com/.well-known/did.json')),
      );
    });

    test('should resolve successfully with paths', () async {
      when(() => response.statusCode).thenReturn(200);
      when(() => response.transform(utf8.decoder))
          .thenAnswer((_) => Stream.value(validDidWebDocument));
      when(() => request.close()).thenAnswer((_) async => response);
      when(
        () => mockClient.getUrl(
          Uri.parse('http://localhost:8892/ingress/did.json'),
        ),
      ).thenAnswer((_) async => request);

      final did = Did.parse('did:web:localhost%3A8892:ingress');
      final result = await DidWeb.resolve(
        did,
        client: mockClient,
      );
      expect(result.didDocument, isNotNull);

      verify(
        () => mockClient
            .getUrl(Uri.parse('http://localhost:8892/ingress/did.json')),
      );
    });
  });
}
