import 'dart:typed_data';

import 'package:web5/web5.dart';
import 'package:test/test.dart';

void main() {
  group('Jws', () {
    test('should successfully sign & verify detached compact jws', () async {
      final did = await DidJwk.create();
      final payload = Uint8List.fromList('hello'.codeUnits);
      final compactJws =
          await Jws.sign(did: did, payload: payload, detachedPayload: true);

      final parts = compactJws.split('.');
      expect(parts.length, equals(3));
      expect(parts[1], equals(''));

      expect(Jws.verify(compactJws, detachedPayload: payload), completes);
    });
  });
}
