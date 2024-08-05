import 'dart:convert';

import 'package:test/test.dart';
import 'package:web5/web5.dart';

void main() {
  group('ed25519', () {
    group('generateKeyPair', () {
      test('should not throw exception when seed is provided', () async {
        final mnemonic = Bip39.generateMnemonic();
        final seed = await Bip39.mnemonicToSeed(mnemonic, desiredKeyLength: 32);

        expect(
          () async => await Ed25519.generatePrivateKey(seed: seed),
          returnsNormally,
        );
      });
    });
  });
}
