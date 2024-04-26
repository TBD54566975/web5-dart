import 'package:test/test.dart';
import 'package:web5/src/dids/did_resolver.dart';
import 'package:web5/web5.dart';

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
      // final resolutionResult = await DidResolver.resolve(
      //   'did:dht:k3nic44ie3wgwuksejbfccjagikrq6dpka3gaidfe3wdnw3te3sigt1kxbkwgcdacjnfw5nsgfp8g3kg8fegr411p3ozqxj7',
      // );

      /*
      KEY ALIAS: GQ6evSVoZHHzAkAlIO84Qw0UORwRTGz_dXabdxEjji8
IDENTITY KEY: {"kty":"OKP","alg":"EdDSA","kid":"GQ6evSVoZHHzAkAlIO84Qw0UORwRTGz_dXabdxEjji8","crv":"Ed25519","x":"OHLcg5tPhsw8P0mH4adMWBUrfNb9gNwj5rgZuM45auo"}
did:dht:koagouk3gjtun3ngejzsgc5dgtkweouwkpnfr4n4ewaiowmck3hiw43ipf8iq3nxco3g6cmdpi1gn3nigyarhi4ggft8qxj7
IDENTITY KEY: [84, 48, 104, 77, 89, 50, 99, 49, 100, 70, 66, 111, 99, 51, 99, 52, 85, 68, 66, 116, 83, 68, 82, 104, 90, 69, 49, 88, 81, 108, 86, 121, 90, 107, 53, 105, 79, 87, 100, 79, 100, 50, 111, 49, 99, 109, 100, 97, 100, 85, 48, 48, 78, 87, 70, 49, 98, 119, 61, 61]
"invalid z32 encoded ed25519 public key"
      */

      final dht = await DidDht.create(publish: true);
      print(dht.uri);
      final did = Did.parse(dht.uri);
      final x = await DidDht.resolve(did);
      expect(x.didDocument, isNotNull);
    });
  });
}
