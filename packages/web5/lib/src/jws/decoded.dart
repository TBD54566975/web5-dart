import 'dart:convert';
import 'dart:typed_data';

import 'package:web5/src/crypto.dart';
import 'package:web5/src/jws/header.dart';
import 'package:web5/src/dids.dart';

class DecodedJws {
  final JwsHeader header;
  final Uint8List payload;
  final Uint8List signature;
  final List<String> parts;

  DecodedJws({
    required this.header,
    required this.payload,
    required this.signature,
    required this.parts,
  });

  Future<void> verify() async {
    if (header.kid == null || header.alg == null) {
      throw Exception(
        'Malformed JWS. expected header to contain kid and alg.',
      );
    }

    final dereferenceResult = await DidResolver.dereference(header.kid!);
    if (dereferenceResult.hasError()) {
      throw Exception(
        'Verification failed. Failed to dereference kid. Error: ${dereferenceResult.dereferencingMetadata.error}',
      );
    }

    final didResource = dereferenceResult.contentStream;
    if (didResource == null) {
      throw Exception(
        'Verification failed. Expected header kid to dereference a verification method',
      );
    }

    if (didResource is! DidVerificationMethod) {
      throw Exception(
        'Verification failed. Expected header kid to dereference a verification method',
      );
    }

    if (didResource.publicKeyJwk == null) {
      throw Exception(
        'Verification failed. Expected header kid to dereference a verification method with a public key',
      );
    }

    final toSign = [parts[0], parts[1]].join('.');
    final toSignBytes = utf8.encode(toSign);

    await Crypto.verify(
      publicKey: didResource.publicKeyJwk!,
      payload: toSignBytes,
      signature: signature,
    );
  }
}
