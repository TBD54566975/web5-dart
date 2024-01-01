import 'dart:convert';
import 'dart:typed_data';

import 'package:tbdex/src/crypto/jwk.dart';
import 'package:tbdex/src/crypto/secp256k1.dart';
import 'package:tbdex/src/extensions/base64url.dart';
import 'package:test/test.dart';

void main() {
  test('should work', () async {
    final secp256k1 = Secp256k1();

    // final privateKey = await secp256k1.generatePrivateKey();
    // print(privateKey);
    final jsonPrivateKey = json.decode(
      '{"kty":"EC","alg":"ES256K","kid":"eeQlHHu6B556BTrOmNpKfb2v0JSgXKfII-tAFY9VLtI","crv":"secp256k1","d":"noAEkAGpDqLOPr-3fOo3sE5lBxfmG05tpDsMW3P7P4s","x":"a0eC-lkNtX6MuTsQ2Z6z_H3NuRMrlwVlJZRtCi_k_Q4","y":"-jvEaLYBfqmza5rdvmjb11-NRHra2ZJQ4TuTUWc_e7c"}',
    );

    final privateKey = Jwk.fromJson(jsonPrivateKey);

    final payload = Uint8List.fromList(utf8.encode("hello"));

    final signature = await secp256k1.sign(privateKey, payload);
    final sigb64url = Base64Codec.urlSafe().encoder.convertNoPadding(signature);
    print(sigb64url);
  });
}
