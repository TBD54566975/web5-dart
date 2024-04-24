import 'package:web5/src/dids/did_dht/dns_packet/answer.dart';
import 'package:web5/src/dids/did_dht/dns_packet/name.dart';
import 'package:web5/src/dids/did_dht/dns_packet/record_class.dart';
import 'package:web5/src/dids/did_dht/dns_packet/record_type.dart';
import 'package:web5/src/dids/did_dht/dns_packet/txt_data.dart';
import 'package:web5/web5.dart';

/// Relevant [spec text](https://did-dht.com/#verification-method-record)
class VerificationMethodRecord {
  /// relevant [spec text](https://did-dht.com/registry/index.html#key-type-index)
  static final Map<String, String> _keyTypeToIndex = {
    Ed25519.crv: '0',
    Secp256k1.crv: '1',
  };

  /// relevant [spec text](https://did-dht.com/registry/index.html#key-type-index)
  static final Map<String, AlgorithmId> _indexToKeyType = {
    '0': AlgorithmId.ed25519,
    '1': AlgorithmId.secp256k1,
  };

  static Set<String> txtEntryNames = {'id', 't', 'k', 'a', 'c'};

  static Answer<TxtData> createTxtRecord(
    int idx,
    DidVerificationMethod method,
  ) {
    final pubKey = Crypto.publicKeyToBytes(method.publicKeyJwk!);
    final keyTypeIndex = _keyTypeToIndex[method.publicKeyJwk!.crv!];
    final data = [
      'id=${method.id.split('#').last}',
      't=$keyTypeIndex',
      'k=${Base64Url.encode(pubKey)}',
    ].join(';');

    return Answer<TxtData>(
      name: RecordName('_k$idx._did'),
      type: RecordType.TXT,
      klass: RecordClass.IN,
      data: TxtData([data]),
      ttl: 7200,
    );
  }

  static DidVerificationMethod createVerificationMethod(
    String did,
    Answer<TxtData> record,
  ) {
    final map = {};

    final fields = record.data.value.first.split(';');
    for (final field in fields) {
      final parts = field.split('=');
      if (parts.length != 2) {
        throw Exception('Invalid verification method format');
      }

      final [key, value] = parts;
      map[key] = value;
    }

    final keyType = _indexToKeyType[map['t']];
    if (keyType == null) {
      throw Exception('Unsupported key type: ${map['t']}');
    }

    final pubKey = Crypto.bytesToPublicKey(keyType, Base64Url.decode(map['k']));
    final vmIdFragment = map['id'] ?? pubKey.computeThumbprint();
    return DidVerificationMethod(
      id: '$did#$vmIdFragment',
      type: 'JsonWebKey',
      controller: map['c'] ?? did,
      publicKeyJwk: pubKey,
    );
  }
}
