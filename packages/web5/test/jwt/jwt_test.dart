import 'package:web5/web5.dart';
import 'package:test/test.dart';

void main() {
  group('Jwt', () {
    test('should decode signed JWT', () async {
      final did = await DidJwk.create();

      final signedJwt =
          await Jwt.sign(did: did, payload: JwtClaims(iss: did.uri));

      final parsedJwt = Jwt.decode(signedJwt);
      expect(parsedJwt.header.kid, contains('${did.uri}#'));
      expect(parsedJwt.claims.iss, equals(did.uri));
    });

    test('should verify JWT signed by did:jwk', () async {
      final did = await DidJwk.create();

      final signedJwt =
          await Jwt.sign(did: did, payload: JwtClaims(iss: did.uri));

      await Jwt.verify(signedJwt);
    });

    test('should verify signed JWT signed by did:dht', () async {
      final did = await DidDht.create(publish: true);

      final signedJwt =
          await Jwt.sign(did: did, payload: JwtClaims(iss: did.uri));

      await Jwt.verify(signedJwt);
    });
  });
}
