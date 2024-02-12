import 'dart:typed_data';

import 'package:web5/src/crypto.dart';
import 'package:web5/src/jws/jws_header.dart';

import 'package:web5/src/dids.dart';

class DecodedJws {
  final JwsHeader header;
  final Uint8List payload;
  final Uint8List signature;
  final List<String> parts;

  static final _didResolver =
      DidResolver(methodResolvers: [DidJwk.resolver, DidDht.resolver]);

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

    final dereferenceResult = await _didResolver.dereference(header.kid!);
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

    final publicKeyJwk = didResource.publicKeyJwk;
    final dsaName =
        DsaName.findByAlias(algorithm: header.alg, curve: publicKeyJwk!.crv);

    if (dsaName == null) {
      throw Exception('${header.alg}:${publicKeyJwk.crv} not supported.');
    }

    await DsaAlgorithms.verify(
      algName: dsaName,
      publicKey: publicKeyJwk,
      payload: payload,
      signature: signature,
    );
  }
}
