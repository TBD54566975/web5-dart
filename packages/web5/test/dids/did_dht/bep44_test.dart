import 'dart:convert';

import 'package:test/test.dart';
import 'package:web5/src/dids/did_dht/bep44.dart';

void main() {
  group('BEP44', () {
    test('Sign', () {
      final payload = utf8.encode('v=1,b=2,c=3');
      // Bep44Message(k: k, seq: seq, sig: sig, v: v);
    });
  });
}
