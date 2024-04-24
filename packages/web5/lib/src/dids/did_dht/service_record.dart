import 'package:web5/src/dids/did_dht/dns_packet/answer.dart';
import 'package:web5/src/dids/did_dht/dns_packet/name.dart';
import 'package:web5/src/dids/did_dht/dns_packet/record_class.dart';
import 'package:web5/src/dids/did_dht/dns_packet/record_type.dart';
import 'package:web5/src/dids/did_dht/dns_packet/txt_data.dart';
import 'package:web5/web5.dart';

class ServiceRecord {
  static Set<String> txtEntryNames = {'id', 't', 'se'};

  static Answer<TxtData> createTxtRecord(int idx, DidService service) {
    return Answer<TxtData>(
      name: RecordName('_s$idx._did'),
      type: RecordType.TXT,
      klass: RecordClass.IN,
      data: TxtData([
        'id=${service.id};t=${service.type};se=${service.serviceEndpoint}',
      ]),
      ttl: 7200,
    );
  }

  static DidService createService(String did, Answer<TxtData> record) {
    final Map<String, String> map = {};

    final fields = record.data.value.first.split(';');
    for (final field in fields) {
      final parts = field.split('=');
      if (parts.length != 2) {
        throw Exception('Invalid verification method format');
      }

      final [key, value] = parts;
      map[key] = value;
    }

    for (final entry in txtEntryNames) {
      if (!map.containsKey(entry)) {
        throw Exception('service record Missing entry: $entry');
      }
    }

    return DidService(
      id: '$did#${map['id']!}',
      type: map['t']!,
      serviceEndpoint: map['se']!.split(','),
    );
  }

  // factory ServiceRecord.fromService(DidService service) {
  //   return ServiceRecord(
  //     id: service.id,
  //     type: service.type,
  //     rData: TxtData([
  //       'id=${service.id};t=${service.type};se=${service.serviceEndpoint};',
  //     ]),
  //     ttl: 7200,
  //     serviceEndpoint: service.serviceEndpoint,
  //   );
  // }

  // DidService toService() {
  //   return DidService(
  //     id: id,
  //     type: type,
  //     serviceEndpoint: serviceEndpoint ?? '',
  //   );
  // }
}
