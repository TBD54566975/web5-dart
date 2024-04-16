import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:test/test.dart';
import 'package:web5/src/dids/did_dht/dns/answer.dart';
import 'package:web5/src/dids/did_dht/dns/name.dart';
import 'package:web5/src/dids/did_dht/dns/record_class.dart';
import 'package:web5/src/dids/did_dht/dns/record_type.dart';
import 'package:web5/src/dids/did_dht/dns/txt_data.dart';

void main() {
  group('DNS Answer', () {
    test('encoding / decoding should work', () {
      final answer = Answer<TxtData>(
        name: RecordName(
          '_k1._did.hpmp9uur565nkimpwdzom7ehbuabnsba658xwwynyk7awcd15bko',
        ),
        type: RecordType.TXT,
        klass: RecordClass.IN,
        data: TxtData(
          ['id=sig;t=0;k=Ix9rT44QKnIjNeB51-ORlwoCbLKr-hsOYgl4gN9TzIU'],
        ),
        ttl: 7200,
      );

      final result = Answer.codec.encode(answer);
      final vector = hex.decode(
        '035f6b31045f6469643468706d70397575723536356e6b696d7077647a6f6d376568627561626e736261363538787777796e796b37617763643135626b6f000010000100001c2000393869643d7369673b743d303b6b3d49783972543434514b6e496a4e654235312d4f526c776f43624c4b722d68734f59676c34674e39547a4955',
      );

      expect(result.value, vector);

      final decoded = Answer.codec.decode(Uint8List.fromList(vector));
      expect(decoded.value.data is TxtData, isTrue);
      expect(
        const ListEquality().equals(
          (decoded.value.data as TxtData).value,
          ['id=sig;t=0;k=Ix9rT44QKnIjNeB51-ORlwoCbLKr-hsOYgl4gN9TzIU'],
        ),
        isTrue,
      );

      expect(decoded.value.name.value, answer.name.value);
      expect(decoded.value.type, answer.type);
      expect(decoded.value.klass, answer.klass);
      expect(decoded.value.ttl, answer.ttl);
    });
  });
}
