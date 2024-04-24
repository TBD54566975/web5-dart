import 'package:test/test.dart';
import 'package:web5/src/dids/did_dht/dns_packet.dart';
import 'package:web5/src/dids/did_dht/service_record.dart';
import 'package:web5/web5.dart';

void main() {
  group('ServiceRecord', () {
    group('createService', () {
      test('should return a DidService', () {
        final vector = Answer<TxtData>(
          name: RecordName('_s0._did'),
          type: RecordType.TXT,
          klass: RecordClass.IN,
          data: TxtData([
            'id=tbdex;t=tbdex;se=https://somepfi.com/tbdex',
          ]),
          ttl: 7200,
        );

        final did =
            'did:dht:i9xkp8ddcbcg8jwq54ox699wuzxyifsqx4jru45zodqu453ksz6y';

        final service = ServiceRecord.createService(did, vector);

        expect(service.id, contains('$did#'));
        expect(service.type, equals('tbdex'));
        expect(service.serviceEndpoint, equals(['https://somepfi.com/tbdex']));
      });

      test('should throw exception if required field is missing', () {
        final vector = Answer<TxtData>(
          name: RecordName('_s0._did'),
          type: RecordType.TXT,
          klass: RecordClass.IN,
          data: TxtData([
            't=tbdex;se=https://somepfi.com/tbdex',
          ]),
          ttl: 7200,
        );

        final did =
            'did:dht:i9xkp8ddcbcg8jwq54ox699wuzxyifsqx4jru45zodqu453ksz6y';

        expect(
          () => ServiceRecord.createService(did, vector),
          throwsException,
          reason: 'service record Missing entry: id',
        );
      });
    });

    group('createTxtRecord', () {
      test('should return a TXT Record', () {
        final service = DidService(
          id: '#tbdex',
          type: 'tbdex',
          serviceEndpoint: ['https://somepfi.com/tbdex'],
        );

        final vector = ServiceRecord.createTxtRecord(0, service);

        expect(vector.name.value, equals('_s0._did'));
        expect(vector.type, equals(RecordType.TXT));
        expect(vector.klass, equals(RecordClass.IN));
        expect(
          vector.data.value,
          equals(['id=tbdex;t=tbdex;se=https://somepfi.com/tbdex']),
        );
        expect(vector.ttl, equals(7200));
      });
    });
  });
}
