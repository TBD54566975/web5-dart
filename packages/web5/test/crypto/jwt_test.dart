import 'package:web5/src/jwt.dart';
import 'package:web5/web5.dart';
import 'package:test/test.dart';

void main() {
  group('Jwt', () {
    test('should parse signed JWT', () async {
      final km = InMemoryKeyManager();
      final did = await DidJwk.create(keyManager: km);

      final signedJwt =
          await Jwt.sign(did: did, jwtPayload: JwtPayload(iss: did.uri));

      final parsedJwt = Jwt.parse(signedJwt);
      expect(parsedJwt.decoded.header.kid, contains("${did.uri}#"));
      expect(parsedJwt.decoded.payload.iss, equals(did.uri));
    });
  });
}
