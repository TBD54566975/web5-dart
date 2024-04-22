import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:test/test.dart';
import 'package:web5/src/dids/did_dht/dns_packet/header.dart';

void main() {
  group('DNS Header', () {
    test('should encode/decode dns header', () {
      final vector = hex.decode('000084000000000500000000');
      final header = Header.decode(Uint8List.fromList(vector));

      expect(header.numQuestions, 0);
      expect(header.numAnswers, 5);
    });
  });
}
