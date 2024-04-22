import 'package:web5/src/dids/did_dht/dns_packet/answer.dart';
import 'package:web5/src/dids/did_dht/dns_packet/name.dart';
import 'package:web5/src/dids/did_dht/dns_packet/record_class.dart';
import 'package:web5/src/dids/did_dht/dns_packet/record_type.dart';
import 'package:web5/src/dids/did_dht/dns_packet/txt_data.dart';
import 'package:web5/web5.dart';

class VerificationMethodRecord {
  static Set<String> txtEntryNames = {'id', 't', 'k', 'a', 'c'};

  static Answer<TxtData> toTxtRecord(
    int idx,
    DidVerificationMethod method,
  ) {
    final pubKey = Crypto.publicKeyToBytes(method.publicKeyJwk!);
    final data = ['id=${method.id}', 't=$idx', 'k=${Base64Url.encode(pubKey)}']
        .join(';');

    return Answer<TxtData>(
      name: RecordName('_k$idx._did'),
      type: RecordType.TXT,
      klass: RecordClass.IN,
      data: TxtData([data]),
      ttl: 0,
    );
  }

  static DidVerificationMethod toDidVerificationMethod(Answer<TxtData> record) {
    final txtData = record.data;
    throw UnimplementedError();
  }
}
