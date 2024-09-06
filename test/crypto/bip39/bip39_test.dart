import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:web5/web5.dart';
import 'package:test/test.dart';
import 'package:convert/convert.dart';

void main() {
  final vectorPath = '${Directory.current.path}/test/crypto/bip39/vectors.json';
  final Map<String, dynamic> vectors =
      json.decode(File(vectorPath).readAsStringSync(encoding: utf8));

  int i = 0;
  for (var list in (vectors['english'] as List<dynamic>)) {
    testVector(list, i);
    i++;
  }

  group('invalid entropy', () {
    test('throws for empty entropy', () {
      expect(
        () => Bip39.entropyToMnemonic(Uint8List(0)),
        throwsA(isA<InvalidEntropyException>()),
      );
    });

    test('throws for entropy that\'s not a multiple of 4 bytes', () async {
      expect(
        () => Bip39.entropyToMnemonic(Uint8List(6)),
        throwsA(isA<InvalidEntropyException>()),
      );
    });

    test('throws for entropy that is larger than 32 bytes', () async {
      expect(
        () => Bip39.entropyToMnemonic(Uint8List(33)),
        throwsA(isA<InvalidEntropyException>()),
      );
    });
  });

  test('validateMnemonic', () {
    expect(
      Bip39.validateMnemonic(['sleep', 'kitten']),
      isFalse,
      reason: 'fails for a mnemonic that is too short',
    );

    expect(
      Bip39.validateMnemonic(
        ['sleep', 'kitten', 'sleep', 'kitten', 'sleep', 'kitten'],
      ),
      isFalse,
      reason: 'fails for a mnemonic that is too short',
    );

    expect(
      Bip39.validateMnemonic(
        [
          'turtle',
          'front',
          'uncle',
          'idea',
          'crush',
          'write',
          'shrug',
          'there',
          'lottery',
          'flower',
          'risky',
          'shell',
        ],
      ),
      isFalse,
      reason: 'fails if mnemonic words are not in the word list',
    );

    expect(
      Bip39.validateMnemonic(
        [
          'sleep',
          'kitten',
          'sleep',
          'kitten',
          'sleep',
          'kitten',
          'sleep',
          'kitten',
          'sleep',
          'kitten',
          'sleep',
          'kitten',
        ],
      ),
      isFalse,
      reason: 'fails for invalid checksum',
    );
  });

  group('generateMnemonic', () {
    test('can vary entropy length', () async {
      final words = Bip39.generateMnemonic(strength: 160);
      expect(
        words.length,
        equals(15),
        reason: 'can vary generated entropy bit length',
      );
    });

    test('requests the exact amount of data from an RNG', () {
      Bip39.generateMnemonic(
        strength: 160,
        randomBytes: (int size) {
          expect(size, 160 ~/ 8);
          return Uint8List(size);
        },
      );
    });
  });
}

void testVector(List<dynamic> v, int i) {
  final ventropy = v[0];
  final vmnemonic = v[1].split(' ');
  final vseedHex = v[2];

  group('for English($i), $ventropy', () {
    test('mnemonic to entropy', () {
      final entropy = Bip39.mnemonicToEntropy(vmnemonic);
      expect(hex.encode(entropy), equals(ventropy));
    });

    test('mnemonic to seed hex', () async {
      final seedHex = hex
          .encode(await Bip39.mnemonicToSeed(vmnemonic, passphrase: 'TREZOR'));
      expect(seedHex, equals(vseedHex));
    });

    test('entropy to mnemonic', () {
      final code = Bip39.entropyToMnemonic(
        Uint8List.fromList(hex.decode(ventropy)),
      );
      expect(code, equals(vmnemonic));
    });

    test('generate mnemonic', () {
      final code = Bip39.generateMnemonic(
        randomBytes: (int size) => Uint8List.fromList(hex.decode(ventropy)),
      );
      expect(
        code,
        equals(vmnemonic),
        reason: 'generateMnemonic returns randomBytes entropy unmodified',
      );
    });

    test('validate mnemonic', () async {
      expect(
        Bip39.validateMnemonic(vmnemonic),
        isTrue,
        reason: 'validateMnemonic returns true',
      );
    });
  });
}
