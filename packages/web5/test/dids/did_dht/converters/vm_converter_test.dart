import 'package:test/test.dart';
import 'package:web5/src/dids/did_dht/dns_packet.dart';
import 'package:web5/src/dids/did_dht/converters/vm_converter.dart';

void main() {
  group('VerificationMethodConverter', () {
    group('convertTxtRecord', () {
      test('should return a DidVerificationMethod', () {
        final vector = Answer<TxtData>(
          name: RecordName('_k0._did'),
          type: RecordType.TXT,
          klass: RecordClass.IN,
          data: TxtData([
            't=0;k=afdea69c63605863a68edea0ff7ff49dde0a96ce7e9249eb7780dd3d6f2ab5fc;a=Ed25519',
          ]),
          ttl: 7200,
        );

        final did =
            'did:dht:i9xkp8ddcbcg8jwq54ox699wuzxyifsqx4jru45zodqu453ksz6y';
        final vm = VerificationMethodConverter.convertTxtRecord(did, vector);

        expect(vm.controller, equals(did));
        expect(vm.id, contains('$did#'));
        expect(vm.type, equals('JsonWebKey'));
        expect(vm.publicKeyJwk!.crv, equals('Ed25519'));
      });
    });
  });
}
