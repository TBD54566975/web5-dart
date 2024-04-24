import 'package:test/test.dart';
import 'package:web5/src/dids/did_dht/dns_packet.dart';
import 'package:web5/src/dids/did_dht/service_record.dart';

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
  });
}
