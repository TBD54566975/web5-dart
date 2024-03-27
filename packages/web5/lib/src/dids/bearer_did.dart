import 'dart:typed_data';

import 'package:web5/src/crypto.dart';
import 'package:web5/src/dids/did_core.dart';
import 'package:web5/src/dids/portable_did.dart';

typedef Signer = Future<Uint8List> Function(Uint8List payload);

class DidSigner {
  DidVerificationMethod verificationMethod;
  Signer sign;

  DidSigner({
    required this.verificationMethod,
    required this.sign,
  });
}

class BearerDid {
  String uri;
  KeyManager keyManager;
  DidDocument document;
  DidDocumentMetadata metadata;

  BearerDid({
    required this.uri,
    required this.keyManager,
    required this.document,
    this.metadata = const DidDocumentMetadata(),
  });

  Future<PortableDid> export() async {
    final portableDid = PortableDid(
      uri: uri,
      document: document,
    );

    if (keyManager is! KeyExporter) {
      return Future.value(portableDid);
    }

    final keyExporter = keyManager as KeyExporter;
    for (final vm in document.verificationMethod!) {
      final publicKeyJwk = vm.publicKeyJwk!;
      final keyId = publicKeyJwk.computeThumbprint();
      final jwk = await keyExporter.export(keyId);

      portableDid.privateKeys.add(jwk);
    }

    return portableDid;
  }

  static Future<BearerDid> import(
    PortableDid portableDid, {
    KeyManager? keyManager,
  }) {
    if (keyManager == null) {
      final defaultKeyManager = InMemoryKeyManager();

      for (final jwk in portableDid.privateKeys) {
        defaultKeyManager.import(jwk);
      }

      keyManager = defaultKeyManager;
    }

    return Future.value(
      BearerDid(
        uri: portableDid.uri,
        keyManager: keyManager,
        document: portableDid.document,
      ),
    );
  }

  Future<DidSigner> getSigner({
    VerificationPurpose? purpose,
    String? verificationMethodId,
  }) async {
    // if no purpose or verificationMethodId is provided, use the first
    final DidVerificationMethod? vm = document.getVerificationMethod(
      id: verificationMethodId,
      purpose: purpose,
    );

    if (vm == null) {
      throw Exception('No private key found to sign with');
    }

    if (vm.publicKeyJwk == null) {
      throw Exception('could not determine key id');
    }

    final keyId = vm.publicKeyJwk!.computeThumbprint();

    sign(Uint8List payload) {
      return keyManager.sign(keyId, payload);
    }

    return DidSigner(
      verificationMethod: vm,
      sign: sign,
    );
  }
}
