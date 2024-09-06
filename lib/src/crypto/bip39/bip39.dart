import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/dart.dart';
import 'package:web5/src/crypto/bip39/wordlists/english.dart';
import 'package:web5/src/crypto/bip39/pbkdf2.dart';

class Bip39 {
  static const int _sizeByte = 255;
  static const _sha256 = DartSha256();

  static int _binaryToByte(String binary) => int.parse(binary, radix: 2);

  static String _bytesToBinary(Uint8List bytes) =>
      bytes.map((byte) => byte.toRadixString(2).padLeft(8, '0')).join('');

  static _deriveChecksumBits(Uint8List entropy) {
    final checksumLengthBits = (entropy.length * 8) ~/ 32;
    final hash = Uint8List.fromList(_sha256.hashSync(entropy).bytes);

    return _bytesToBinary(hash).substring(0, checksumLengthBits);
  }

  static Uint8List _defaultRandomBytes(int size) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List.generate(size, (_) => rng.nextInt(_sizeByte)),
    );
  }

  static List<String> generateMnemonic({
    int strength = 128,
    Uint8List Function(int) randomBytes = _defaultRandomBytes,
  }) {
    assert(strength % 32 == 0);

    final entropy = randomBytes(strength ~/ 8);
    return entropyToMnemonic(entropy);
  }

  static List<String> entropyToMnemonic(Uint8List entropy) {
    if (entropy.length < 16 || entropy.length > 32 || entropy.length % 4 != 0) {
      throw InvalidEntropyException('entropy ');
    }

    final entropyBits = _bytesToBinary(Uint8List.fromList(entropy));
    final checksumBits = _deriveChecksumBits(Uint8List.fromList(entropy));
    final bits = '$entropyBits$checksumBits';

    final regex = RegExp(r'.{1,11}');
    final chunks = regex
        .allMatches(bits)
        .map((match) => match.group(0)!)
        .toList(growable: false);

    return chunks.map((binary) => WORDLIST[_binaryToByte(binary)]).toList();
  }

  static Future<Uint8List> mnemonicToSeed(
    List<String> mnemonic, {
    String passphrase = '',
    int desiredKeyLength = 64,
  }) async {
    final pbkdf2 = Pbkdf2(desiredKeyLength: desiredKeyLength);
    return pbkdf2.process(mnemonic.join(' '), passphrase: passphrase);
  }

  static bool validateMnemonic(List<String> mnemonic) {
    try {
      mnemonicToEntropy(mnemonic);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Uint8List mnemonicToEntropy(List<String> mnemonic) {
    if (mnemonic.length % 3 != 0) {
      throw InvalidMnemonicException();
    }

    final bits = mnemonic.map((word) {
      final index = WORDLIST.indexOf(word);
      if (index == -1) {
        throw InvalidMnemonicException();
      }
      return index.toRadixString(2).padLeft(11, '0');
    }).join('');

    final dividerIndex = (bits.length / 33).floor() * 32;
    final entropyBits = bits.substring(0, dividerIndex);
    final checksumBits = bits.substring(dividerIndex);

    final regex = RegExp(r'.{1,8}');
    final groupedBits = regex
        .allMatches(entropyBits)
        .map((match) => _binaryToByte(match.group(0)!))
        .toList(growable: false);

    final entropyBytes = Uint8List.fromList(groupedBits);

    if (entropyBytes.length < 16 ||
        entropyBytes.length > 32 ||
        entropyBytes.length % 4 != 0) {
      throw InvalidEntropyException();
    }

    final newChecksum = _deriveChecksumBits(entropyBytes);
    if (newChecksum != checksumBits) {
      throw InvalidChecksumException();
    }

    return entropyBytes;
  }
}

class InvalidMnemonicException implements Exception {
  final String message;
  InvalidMnemonicException([this.message = 'Invalid mnemonic']);
  @override
  String toString() => 'InvalidMnemonicException: $message';
}

class InvalidEntropyException implements Exception {
  final String message;
  InvalidEntropyException([this.message = 'Invalid entropy']);
  @override
  String toString() => 'InvalidEntropyException: $message';
}

class InvalidChecksumException implements Exception {
  final String message;
  InvalidChecksumException([this.message = 'Invalid mnemonic checksum']);
  @override
  String toString() => 'InvalidChecksumException: $message';
}
