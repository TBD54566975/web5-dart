import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:test/test.dart';
import 'package:web5/web5.dart';

import '../../helpers/mocks.dart';

const testVector =
    '85ad53bb66db27eba9799d807a1dff1b43823263b72a0824aad94026980048ccbdfc3fdfe9355c243c32f5ed0f40ab3917b925783f6e49b6cd1a73333691e80c000000006625fa11000084000000000300000000035f6b30045f646964343377686674677062646a696878397a653974646e3537357a717a6d347177636365746e66317962696962757a61643772726d7979000010000100001c2000373669643d303b743d303b6b3d7a5468596d6145616138662d365078474c6664336464656e5559784552466b414e61686e66412d6b497341035f7330045f646964343377686674677062646a696878397a653974646e3537357a717a6d347177636365746e66317962696962757a61643772726d7979000010000100001c2000272669643d7066693b743d5046493b73653d68747470733a2f2f6c6f63616c686f73743a39303030045f646964343377686674677062646a696878397a653974646e3537357a717a6d347177636365746e66317962696962757a61643772726d7979000010000100001c20002e2d763d303b766d3d6b303b617574683d6b303b61736d3d6b303b64656c3d6b303b696e763d6b303b7376633d7330';

void main() {
  late MockHttpClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockHttpClient();
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
      when(
        () => mockHttpClient.get(
          Uri.parse(
            'https://diddht.tbddev.org/3whftgpbdjihx9ze9tdn575zqzm4qwccetnf1ybiibuzad7rrmyy',
          ),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(String.fromCharCodes(hex.decode(testVector)), 200),
      );

      final did = Did.parse(
        'did:dht:3whftgpbdjihx9ze9tdn575zqzm4qwccetnf1ybiibuzad7rrmyy',
      );
      final resolutionResult = await DidDht.resolve(
        did,
        client: mockHttpClient,
      );

      expect(resolutionResult.didDocument, isNotNull);
      expect(
        'did:dht:3whftgpbdjihx9ze9tdn575zqzm4qwccetnf1ybiibuzad7rrmyy',
        resolutionResult.didDocument?.id,
      );

      verify(
        () => mockHttpClient.get(
          Uri.parse(
            'https://diddht.tbddev.org/3whftgpbdjihx9ze9tdn575zqzm4qwccetnf1ybiibuzad7rrmyy',
          ),
        ),
      ).called(1);
    });
  });
}
