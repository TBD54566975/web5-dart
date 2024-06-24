import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:web5/src/dids/did_dht/bencoder.dart';

void main() {
  group('Bencoder', () {
    group('String', () {
      final vectors = [
        {'input': 'spam', 'expected': '4:spam'}, // 4:spam
        {'input': '', 'expected': '0:'}, // 0:
      ];

      for (var v in vectors) {
        test('should correctly encode strings', () {
          final actual = Bencoder.bencode(v['input']);
          expect(actual, equals(v['expected']));
        });
      }
    });

    group('Integer', () {
      final vectors = [
        {'input': 0, 'expected': 'i0e'}, // i0e
        {'input': 42, 'expected': 'i42e'}, // i42e
        {'input': -42, 'expected': 'i-42e'}, // i-42e
      ];

      for (var v in vectors) {
        test('should correctly encode integers', () {
          final actual = Bencoder.bencode(v['input']);
          expect(actual, equals(v['expected']));
        });
      }
    });

    group('Uint8List', () {
      final vectors = [
        {'input': utf8.encode('{}'), 'expected': '2:{}'}, // 2:{}
        {'input': Uint8List.fromList([]), 'expected': '0:'}, // 0:
      ];

      for (var v in vectors) {
        test('should correctly encode byte strings', () {
          final actual = Bencoder.bencode(v['input']);
          expect(actual, equals(v['expected']));
        });
      }
    });
  });
}
