import 'package:test/test.dart';
import 'package:web5/src/dids/did_dht/dns_packet.dart';

void main() {
  group('DnsPacket', () {
    test('should encode/decode dns name', () {
      final name = DnsName(value: 'hello.a.com');
      final buf = name.encode();

      final decodedName = DnsName.decode(buf, 0);
      print('${name.value} == ${decodedName.value}');
      expect(name.value, decodedName.value);
    });

    test('should encode/decode dns text data', () {
      final txtData = DnsTxtData(['hello', 'world'], 12);
      final buf = txtData.encode();

      final decodedName = DnsTxtData.decode(buf, 0);
      print('${txtData.value} == ${decodedName.value}');
      expect(txtData.value, decodedName.value);
    });

    test('should encode/decode dns packet', () {
      final header = DnsHeader(
        id: 1234,
        qr: false,
        opcode: DnsOpCode.QUERY,
        tc: false,
        rd: true,
        qdcount: 1,
        ancount: 0,
        nscount: 0,
        arcount: 0,
      );

      // Define a DNS question
      final question = DnsQuestion(
        name: DnsName(value: 'example.com'),
        type: DnsType.A,
        klass: DnsClass.IN,
      );
      final answer = DnsAnswer(
        name: DnsName(value: 'example.com'),
        type: DnsType.A,
        ttl: 3600,
        data: DnsTxtData(['hello'], 0),
        klass: DnsClass.IN,
      );
      // Create the DNS packet
      final packet = DnsPacket(
        header: header,
        questions: [question],
        answers: [answer],
      );
      final encoded = packet.encode();

      // Decode the packet from the encoded bytes
      final decodedPacket = DnsPacket.decode(encoded);

      // TODO: fails when decoding header due to byte size not being set properly
      expect(decodedPacket.header.id, equals(packet.header.id));
      expect(decodedPacket.header.qr, equals(packet.header.qr));
      expect(
        decodedPacket.questions.first.name.value,
        equals(packet.questions.first.name.value),
      );
      expect(
        decodedPacket.answers.first.data,
        equals(packet.answers.first.data),
      );
    });
  });
}
