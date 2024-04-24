import 'dart:math';

import 'package:test/test.dart';
import 'package:web5/src/dids/did_dht/dns_packet.dart';
import 'package:web5/src/dids/did_dht/document_packet.dart';
import 'package:web5/web5.dart';

void main() {
  group('DocumentPacket', () {
    test('createDnsPacket', () {
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

      final dnsPacket = DocumentPacket.createDnsPacket(didDocument);
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
  });
}
