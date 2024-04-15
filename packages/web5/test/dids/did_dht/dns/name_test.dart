import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:test/test.dart';
import 'package:web5/src/dids/did_dht/dns/name.dart';

import 'vector.dart';

void main() {
  final vectors = [
    Vector(
      decoded: '_k1._did.hpmp9uur565nkimpwdzom7ehbuabnsba658xwwynyk7awcd15bko',
      encoded: hex.decode(
        '035f6b31045f6469643468706d70397575723536356e6b696d7077647a6f6d376568627561626e736261363538787777796e796b37617763643135626b6f00',
      ),
    ),
  ];
  group('DNS Name', () {
    test('should encode/decode dns name', () {
      for (var vector in vectors) {
        final name = RecordName(vector.decoded);
        final buf = name.encode();

        expect(buf, vector.encoded);

        final decodedName =
            RecordName.decode(Uint8List.fromList(vector.encoded));

        expect(vector.decoded, decodedName.value);
      }
    });
  });
}
