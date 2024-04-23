import 'package:web5/src/dids/did_dht/dns_packet/answer.dart';
import 'package:web5/src/dids/did_dht/dns_packet/name.dart';
import 'package:web5/src/dids/did_dht/dns_packet/record_class.dart';
import 'package:web5/src/dids/did_dht/dns_packet/record_type.dart';
import 'package:web5/src/dids/did_dht/dns_packet/txt_data.dart';
import 'package:web5/web5.dart';

class ServiceRecord {
  static Set<String> txtEntryNames = {'id', 't', 'se'};

  static Answer<TxtData> toTxtRecord(int idx, DidService service) {
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

  static DidService toDidService(Answer<TxtData> record) {
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
    final serviceEndpoint = relationshipsMap['se']?.first;

    return DidService(
      id: id ?? '',
      type: type ?? '',
      serviceEndpoint: serviceEndpoint ?? '',
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
