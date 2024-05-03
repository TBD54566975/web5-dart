import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:web5/src/crypto.dart';
import 'package:test/test.dart';

final thisDir = Directory.current.path;
final vectorDir = '$thisDir/../../web5-spec/test-vectors/crypto_es256k';

class Input {
  String data;
  Jwk key;
  String signature;

  Input({required this.data, required this.key, required this.signature});

  factory Input.fromJson(Map<String, dynamic> json) {
    return Input(
      data: json['data'],
      key: Jwk.fromJson(json['key']),
      signature: json['signature'],
    );
  }
}

class TestVector {
  String description;
  Input input;
  bool? output;
  bool errors;

  TestVector({
    required this.description,
    required this.input,
    this.output,
    this.errors = false,
  });

  factory TestVector.fromJson(Map<String, dynamic> json) {
    return TestVector(
      description: json['description'],
      input: Input.fromJson(json['input']),
      output: json['output'],
      errors: json['errors'],
    );
  }
}

class TestVectors {
  String description;
  List<TestVector> vectors;

  TestVectors({required this.description, required this.vectors});

  factory TestVectors.fromJson(Map<String, dynamic> json) {
    return TestVectors(
      description: json['description'],
      vectors: json['vectors']
          .map<TestVector>((v) => TestVector.fromJson(v))
          .toList(),
    );
  }
}

void main() {
  group('Secp256k1', () {
    group('verify', () {
      group('vectors', () {
        final vectorPath = '$vectorDir/verify.json';
        final file = File(vectorPath);
        late List<TestVector> vectors;
        try {
          final contents = file.readAsStringSync();
          final jsonVectors = json.decode(contents);

          vectors = TestVectors.fromJson(jsonVectors).vectors;
        } catch (e) {
          throw Exception('Failed to load verify test vectors: $e');
        }

        for (final vector in vectors) {
          test(vector.description, () async {
            final signature =
                Uint8List.fromList(hex.decode(vector.input.signature));
            final payload = Uint8List.fromList(hex.decode(vector.input.data));

            try {
              await Secp256k1.verify(vector.input.key, payload, signature);

              if (vector.errors == true) {
                fail('Expected an error but none was thrown');
              }
            } catch (e) {
              if (vector.errors == false) {
                fail('Expected no error but got: $e');
              }
            }
          });
        }
      });
    });
    test('should verify public key', () async {
      final privateKeyJwk = await Secp256k1.generatePrivateKey();
      final payload = Uint8List.fromList(utf8.encode('hello'));
      final signature = await Secp256k1.sign(privateKeyJwk, payload);

      final publicKeyJwk = await Secp256k1.computePublicKey(privateKeyJwk);
      await Secp256k1.verify(publicKeyJwk, payload, signature);
    });
  });
}
