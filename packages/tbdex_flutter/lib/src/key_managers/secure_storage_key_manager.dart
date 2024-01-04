import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tbdex/tbdex.dart';

class SecureStorageKeyManager implements KeyManager {
  final FlutterSecureStorage _storage;
  SecureStorageKeyManager(
      {FlutterSecureStorage storage = const FlutterSecureStorage(
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      )})
      : _storage = storage;

  @override
  Future<String> generatePrivateKey(DsaName alg) async {
    final privateKeyJwk = await DsaAlgorithms.generatePrivateKey(alg);
    final thumbprint = privateKeyJwk.computeThumbprint();
    await _storage.write(key: thumbprint, value: privateKeyJwk.toString());
    return thumbprint;
  }

  @override
  Future<Jwk> getPublicKey(String keyAlias) async {
    final privateKeyJwkStr = await _storage.read(key: keyAlias);

    if (privateKeyJwkStr == null) {
      throw Exception('No key found with alias $keyAlias');
    }

    final privateKeyJwk = Jwk.fromJson(json.decode(privateKeyJwkStr));
    return DsaAlgorithms.computePublicKey(privateKeyJwk);
  }

  @override
  Future<Uint8List> sign(String keyAlias, Uint8List payload) async {
    final privateKeyJwkStr = await _storage.read(key: keyAlias);

    if (privateKeyJwkStr == null) {
      throw Exception('No key found with alias $keyAlias');
    }

    final privateKeyJwk = Jwk.fromJson(json.decode(privateKeyJwkStr));
    return DsaAlgorithms.sign(privateKeyJwk, payload);
  }
}
