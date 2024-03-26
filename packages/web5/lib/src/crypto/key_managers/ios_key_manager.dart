import 'dart:convert';
import 'dart:typed_data';

import 'package:keychain/keychain.dart';
import 'package:web5/web5.dart';

class IosKeyManager implements KeyManager, KeyImporter, KeyExporter {
  @override
  Future<String> generatePrivateKey(AlgorithmId algId) async {
    final Jwk privateKeyJwk = await Crypto.generatePrivateKey(algId);
    final String alias = privateKeyJwk.computeThumbprint();

    await Keychain.set(alias, json.encode(privateKeyJwk.toJson()));
    return alias;
  }

  @override
  Future<Jwk> getPublicKey(String keyId) async {
    return Crypto.computePublicKey(await _retrievePrivateKeyJwk(keyId));
  }

  @override
  Future<Uint8List> sign(String keyAlias, Uint8List payload) async {
    final Jwk privateKeyJwk = await _retrievePrivateKeyJwk(keyAlias);
    return Crypto.sign(privateKeyJwk, payload);
  }

  Future<Jwk> _retrievePrivateKeyJwk(String keyAlias) async {
    final String? encoded = await Keychain.fetch(keyAlias);

    if (encoded == null) {
      throw Exception('key with alias $keyAlias not found.');
    }

    final Jwk privateKeyJwk = Jwk.fromJson(json.decode(encoded));
    return privateKeyJwk;
  }

  @override
  Future<Jwk> export(String keyId) async {
    final String? encoded = await Keychain.fetch(keyId);

    if (encoded != null) {
      return Jwk.fromJson(json.decode(encoded));
    } else {
      return Future.error('Key not found');
    }
  }

  @override
  Future<String> import(Jwk jwk) async {
    final keyId = jwk.computeThumbprint();

    await Keychain.set(keyId, json.encode(jwk.toJson()));
    return Future.value(keyId);
  }
}
