import 'package:convert/convert.dart';
import 'package:test/test.dart';
import 'package:web5/src/dids/did_dht/dns/txt_data.dart';

import 'vector.dart';

void main() {
  final vectors = [
    Vector(
      unmarshaled: ['id=sig;t=0;k=Ix9rT44QKnIjNeB51-ORlwoCbLKr-hsOYgl4gN9TzIU'],
      marshaled: hex.decode(
        '00393869643d7369673b743d303b6b3d49783972543434514b6e496a4e654235312d4f526c776f43624c4b722d68734f59676c34674e39547a4955',
      ),
    ),
  ];
  group('TXT Data', () {
    test('should encode/decode dns txt data', () {
      for (final vector in vectors) {
        final txtData = TxtData(vector.unmarshaled);
        final marshaled = txtData.encode();

        expect(marshaled, vector.marshaled);

        final unmarshaled = TxtData.decode(marshaled);
        expect(unmarshaled.value, vector.unmarshaled);
      }
    });
  });
}
