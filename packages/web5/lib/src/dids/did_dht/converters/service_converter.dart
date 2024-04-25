import 'package:web5/src/dids/did_core.dart';
import 'package:web5/src/dids/did_dht/dns_packet.dart';

/// Class that houses methods to convert a [DidService] to a [Answer<TxtData>]
/// and vice versa.
class ServiceRecordConverter {
  static Set<String> txtEntryNames = {'id', 't', 'se'};

  /// Converts a [DidService] to a [Answer<TxtData>].
  static Answer<TxtData> convertService(int idx, DidService service) {
    final data = [
      'id=${service.id.split('#').last}',
      't=${service.type}',
      'se=${service.serviceEndpoint.join(',')}',
    ].join(';');

    return Answer<TxtData>(
      name: RecordName('_s$idx._did'),
      type: RecordType.TXT,
      klass: RecordClass.IN,
      data: TxtData([data]),
      ttl: 7200,
    );
  }

  /// Converts a [Answer<TxtData>] to a [DidService].
  static DidService convertTxtRecord(String did, Answer<TxtData> record) {
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
