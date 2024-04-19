import 'package:web5/src/dids/did_dht/dns/answer.dart';
import 'package:web5/src/dids/did_dht/dns/name.dart';
import 'package:web5/src/dids/did_dht/dns/record_class.dart';
import 'package:web5/src/dids/did_dht/dns/record_type.dart';
import 'package:web5/src/dids/did_dht/dns/txt_data.dart';
import 'package:web5/web5.dart';

class VerificationMethodRecord {
  static Set<String> txtEntryNames = {'id', 't', 'k', 'a', 'c'};

  static Answer<TxtData> toTxtRecord(DidVerificationMethod method) {
    return Answer<TxtData>(
      name: RecordName('https://diddht.tbddev.org'),
      type: RecordType.TXT,
      klass: RecordClass.IN,
      // TODO: fix txt data
      data: TxtData([
        'id=${method.id};t=${method.type};k=${method.controller}a=${method.publicKeyJwk?.alg ?? ''}',
      ]),
      ttl: 0,
    );
  }

  static DidVerificationMethod toDidVerificationMethod(Answer<TxtData> record) {
    final txtData = record.data;

    final Map<String, List<String>> relationshipsMap = {};

    // TODO: is this the right way to index into txtData.value?
    for (final entry in txtData.value[0].split(';')) {
      final splitEntry = entry.split('=');

      if (splitEntry.length != 2) {
        // TODO: figure out more appopriate resolution error to use.
        print('oops');
      }

      final [property, values] = splitEntry;
      final splitValues = values.split(',');

      if (!txtEntryNames.contains(property)) {
        continue;
      }

      for (final value in splitValues) {
        relationshipsMap[property] ??= [];
        relationshipsMap[property]!.add(value);
      }
    }

    final id = relationshipsMap['id']?.first;
    final type = relationshipsMap['t']?.first;
    final pubKey = relationshipsMap['k']?.first;
    final pubKeyJwk = relationshipsMap['a']?.first;
    final controller = relationshipsMap['c']?.first;

    return DidVerificationMethod(
      id: id ?? '',
      type: type ?? '',
      controller: controller ?? 'TODO this needs to be the identity key',
      publicKeyJwk: Jwk(kty: pubKeyJwk ?? ''),
      publicKeyMultibase: pubKey,
    );
  }
}
