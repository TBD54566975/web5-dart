import 'dart:convert';

import 'package:test/test.dart';
import 'package:web5/src/dids/did_dht/dns_packet.dart';
import 'package:web5/src/dids/did_dht/converters/did_document_converter.dart';
import 'package:web5/web5.dart';

void main() {
  group('DidDocumentConverter', () {
    test('convertDidDocument', () {
      final didDocument = DidDocument.fromJson({
        'id': 'did:dht:5cahcfh3zh8bqd5cn3y6inoea1b3d6kh85rjksne9e5dcyrc1ery',
        'verificationMethod': [
          {
            'id':
                'did:dht:5cahcfh3zh8bqd5cn3y6inoea1b3d6kh85rjksne9e5dcyrc1ery#0',
            'type': 'JsonWebKey',
            'controller':
                'did:dht:5cahcfh3zh8bqd5cn3y6inoea1b3d6kh85rjksne9e5dcyrc1ery',
            'publicKeyJwk': {
              'crv': 'Ed25519',
              'kty': 'OKP',
              'x': '2zHGF5m_DhcPbBZB6ooIxIOR-Vw-yJVYSPo2NgCMkgg',
              'kid': 'KDT9PKj4_z7gPk2s279Y-OGlMtt_L93oJzIaiVrrySU',
              'alg': 'EdDSA',
            },
          },
        ],
        'authentication': [
          'did:dht:5cahcfh3zh8bqd5cn3y6inoea1b3d6kh85rjksne9e5dcyrc1ery#0',
        ],
        'assertionMethod': [
          'did:dht:5cahcfh3zh8bqd5cn3y6inoea1b3d6kh85rjksne9e5dcyrc1ery#0',
        ],
        'capabilityDelegation': [
          'did:dht:5cahcfh3zh8bqd5cn3y6inoea1b3d6kh85rjksne9e5dcyrc1ery#0',
        ],
        'capabilityInvocation': [
          'did:dht:5cahcfh3zh8bqd5cn3y6inoea1b3d6kh85rjksne9e5dcyrc1ery#0',
        ],
        'service': [
          {
            'id':
                'did:dht:5cahcfh3zh8bqd5cn3y6inoea1b3d6kh85rjksne9e5dcyrc1ery#tbdex',
            'type': 'tbdex',
            'serviceEndpoint': ['https://somepfi.com/tbdex'],
          },
        ],
      });

      final dnsPacket = DidDocumentConverter.convertDidDocument(didDocument);
      expect(dnsPacket.answers.length, 3);

      for (final answer in dnsPacket.answers) {
        expect(answer, isA<Answer<TxtData>>());
        expect(answer.klass, RecordClass.IN);
        expect(answer.type, RecordType.TXT);
        expect(answer.ttl, 7200);

        final txtRecord = answer as Answer<TxtData>;

        if (answer.name.value == '_did.${didDocument.id}') {
          expect(
            txtRecord.data.value.first,
            'vm=k0;asm=k0;inv=k0;del=k0;auth=k0;srv=s0',
          );
        } else if (answer.name.value.startsWith('_k0')) {
          expect(
            txtRecord.data.value.first,
            'id=0;t=0;k=TW5wSVIwWTFiVjlFYUdOUVlrSmFRalp2YjBsNFNVOVNMVlozTFhsS1ZsbFRVRzh5VG1kRFRXdG5adz09',
          );
        } else if (answer.name.value.startsWith('_s0')) {
          expect(
            txtRecord.data.value.first,
            'id=tbdex;t=tbdex;se=https://somepfi.com/tbdex',
          );
        } else {
          fail('Unexpected answer name: ${answer.name}');
        }
      }
    });

    test('convertDnsPacket', () {
      final answers = [
        Answer<TxtData>(
          name: RecordName(
            '_k0._did.hpmp9uur565nkimpwdzom7ehbuabnsba658xwwynyk7awcd15bko',
          ),
          type: RecordType.TXT,
          klass: RecordClass.IN,
          data: TxtData([
            'id=0;t=0;k=41bfzmTftiVVbaDvBfUcDPARWDj2zvpQAgK7ijBy2FU',
          ]),
          ttl: 7200,
        ),
        Answer<TxtData>(
          name: RecordName(
            '_k1._did.hpmp9uur565nkimpwdzom7ehbuabnsba658xwwynyk7awcd15bko',
          ),
          type: RecordType.TXT,
          klass: RecordClass.IN,
          data: TxtData([
            'id=sig;t=0;k=Ix9rT44QKnIjNeB51-ORlwoCbLKr-hsOYgl4gN9TzIU',
          ]),
          ttl: 7200,
        ),
        Answer<TxtData>(
          name: RecordName(
            '_k2._did.hpmp9uur565nkimpwdzom7ehbuabnsba658xwwynyk7awcd15bko',
          ),
          type: RecordType.TXT,
          klass: RecordClass.IN,
          data: TxtData([
            'id=enc;t=1;k=BGAiiS0vNnoe9L9lcget6zalDDj8ZxBLwZVIa8HwzjupkA76lNJ4i190uJVelQjZ9txYbUU8pyk3axgHxyDRVH8',
          ]),
          ttl: 7200,
        ),
        Answer<TxtData>(
          name: RecordName(
            '_s0._did.hpmp9uur565nkimpwdzom7ehbuabnsba658xwwynyk7awcd15bko',
          ),
          type: RecordType.TXT,
          klass: RecordClass.IN,
          data: TxtData([
            'id=dwn;t=DecentralizedWebNode;se=https://example.com/dwn2;enc=#enc;sig=#sig',
          ]),
          ttl: 7200,
        ),
        Answer<TxtData>(
          name: RecordName(
            '_did.hpmp9uur565nkimpwdzom7ehbuabnsba658xwwynyk7awcd15bko',
          ),
          type: RecordType.TXT,
          klass: RecordClass.IN,
          data: TxtData([
            'v=0;vm=k0,k1,k2;auth=k0,k1;asm=k0,k1;agm=k2;del=k0;inv=k0;svc=s0',
          ]),
          ttl: 7200,
        ),
      ];

      final dnsPacket = DnsPacket.create(answers);
      final did =
          'did:dht:hpmp9uur565nkimpwdzom7ehbuabnsba658xwwynyk7awcd15bko';
      final didDocument = DidDocumentConverter.convertDnsPacket(did, dnsPacket);

      print(didDocument.toJson());
    });
  });
}
