import 'package:web5/web5.dart';
import 'package:test/test.dart';

void main() {
  group('Jwt', () {
    test('should decode signed JWT', () async {
      final km = InMemoryKeyManager();
      final did = await DidJwk.create(keyManager: km);

      final signedJwt =
          await Jwt.sign(did: did, payload: JwtClaims(iss: did.uri));

      final parsedJwt = Jwt.decode(signedJwt);
      expect(parsedJwt.header.kid, contains('${did.uri}#'));
      expect(parsedJwt.claims.iss, equals(did.uri));
    });
  });
}
