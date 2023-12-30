import 'package:tbdex/src/jwt.dart';
import 'package:tbdex/tbdex.dart';
import 'package:test/test.dart';

void main() {
  test('should work', () async {
    final km = InMemoryKeyManager();
    final did = await DidJwk.create(keyManager: km);

    final signedJwt =
        await Jwt.sign(did: did, jwtPayload: JwtPayload(iss: did.uri));

    final parsedJwt = Jwt.parse(signedJwt);
    expect(parsedJwt.decoded.header.kid, contains("${did.uri}#"));
    expect(parsedJwt.decoded.payload.iss, equals(did.uri));
  });
}
