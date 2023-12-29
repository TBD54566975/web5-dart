import "dart:math";
import 'dart:typed_data';

import "package:pointycastle/pointycastle.dart";
import 'package:tbdex/src/crypto/dsa.dart';
import 'package:tbdex/src/crypto/jwk.dart';
import "package:pointycastle/ecc/curves/secp256k1.dart";
import "package:pointycastle/key_generators/ec_key_generator.dart";
import "package:pointycastle/random/fortuna_random.dart";
import 'package:tbdex/src/extensions/bigint.dart';

class Secp256k1 implements Dsa {
  @override
  // TODO: implement algorithm
  String get algorithm => throw UnimplementedError();

  @override
  Future<Jwk> computePublicKey(Jwk privateKey) {
    // TODO: implement computePublicKey
    throw UnimplementedError();
  }

  @override
  // TODO: implement curve
  String get curve => throw UnimplementedError();

  @override
  Future<Jwk> generatePrivateKey() {
    final generatorParams = ECKeyGeneratorParameters(ECCurve_secp256k1());
    final generator = ECKeyGenerator();

    final random = Random.secure();
    final seed =
        Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));

    final rand = FortunaRandom();
    rand.seed(KeyParameter(seed));

    generator.init(ParametersWithRandom(generatorParams, rand));

    final keyPair = generator.generateKeyPair();
    final privateKey = keyPair.privateKey as ECPrivateKey;

    privateKey.d!.toBytes();

    throw UnimplementedError();
  }

  @override
  // TODO: implement name
  DsaName get name => throw UnimplementedError();

  @override
  Future<Uint8List> sign(Jwk privateKey, Uint8List payload) {
    // TODO: implement sign
    throw UnimplementedError();
  }

  @override
  Future<void> verify(Jwk publicKey, Uint8List payload, Uint8List signature) {
    // TODO: implement verify
    throw UnimplementedError();
  }
}
