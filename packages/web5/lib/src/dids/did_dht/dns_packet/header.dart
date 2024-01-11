import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/dns_packet/opcode.dart';
import 'package:web5/src/dids/did_dht/dns_packet/rcode.dart';

class DnsHeader {
  int id;
  bool qr;
  DnsOpCode opcode;
  bool aa;
  bool tc;
  bool rd;
  bool ra;
  bool z;
  bool ad;
  bool cd;
  DnsRCode rcode;
  int qdcount;
  int ancount;
  int nscount;
  int arcount;

  get numQuestions => qdcount;
  get numAnswers => ancount;
  get numAuthorities => nscount;
  get numAdditionals => arcount;

  final numBytes = 12;

  DnsHeader({
    required this.id,
    required this.qr,
    required this.opcode,
    required this.aa,
    required this.tc,
    required this.rd,
    required this.ra,
    required this.z,
    required this.ad,
    required this.cd,
    required this.rcode,
    required this.qdcount,
    required this.ancount,
    required this.nscount,
    required this.arcount,
  });

  factory DnsHeader.decode(Uint8List buf, [int offset = 0]) {
    if (buf.length < 12) throw Exception('Header must be 12 bytes');

    final byteData = ByteData.sublistView(buf);
    final flags = byteData.getUint16(offset + 2, Endian.big);

    return DnsHeader(
      id: byteData.getUint16(offset, Endian.big),
      qr: (flags >> 15) & 0x1 == 1,
      opcode: DnsOpCode.fromValue((flags >> 11) & 0xf),
      aa: (flags >> 10) & 0x1 == 1,
      tc: (flags >> 9) & 0x1 == 1,
      rd: (flags >> 8) & 0x1 == 1,
      ra: (flags >> 7) & 0x1 == 1,
      z: (flags >> 6) & 0x1 == 1,
      ad: (flags >> 5) & 0x1 == 1,
      cd: (flags >> 4) & 0x1 == 1,
      rcode: DnsRCode.fromValue(flags & 0xf),
      qdcount: byteData.getUint16(offset + 4, Endian.big),
      ancount: byteData.getUint16(offset + 6, Endian.big),
      nscount: byteData.getUint16(offset + 8, Endian.big),
      arcount: byteData.getUint16(offset + 10, Endian.big),
    );
  }
}
