import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/key_derivators/api.dart' show Pbkdf2Parameters;
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';

class Pbkdf2 {
  static const int defaultBlockLength = 128;
  static const int defaultIterationCount = 2048;
  static const int defaultDesiredKeyLength = 64;
  static const String saltPrefix = 'mnemonic';

  final int blockLength;
  final int iterationCount;
  final int desiredKeyLength;
  late final PBKDF2KeyDerivator _derivator;

  Pbkdf2({
    this.blockLength = defaultBlockLength,
    this.iterationCount = defaultIterationCount,
    this.desiredKeyLength = defaultDesiredKeyLength,
  }) {
    _derivator = PBKDF2KeyDerivator(HMac(SHA512Digest(), blockLength));
  }

  Uint8List process(String mnemonic, {String passphrase = ''}) {
    final salt = Uint8List.fromList(utf8.encode('$saltPrefix$passphrase'));
    _derivator.reset();
    _derivator.init(Pbkdf2Parameters(salt, iterationCount, desiredKeyLength));
    return _derivator.process(Uint8List.fromList(utf8.encode(mnemonic)));
  }
}
