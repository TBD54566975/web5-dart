import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/dns/codec.dart';
import 'package:web5/src/dids/did_dht/dns/opcode.dart';
import 'package:web5/src/dids/did_dht/dns/rcode.dart';

class Header {
  /// Identifier assigned by the program that generates the query.
  int id;

  /// Whether this message is a query (0), or a response (1)
  bool qr;

  /// Specifies kind of query in this message.
  OpCode opcode;

  /// Specifies that the responding name server is an authority for the domain name in question section.
  bool? aa;

  /// Specifies whether the message was truncated.
  bool tc;

  /// Directs the name server to pursue the query recursively
  bool rd;

  /// Set or cleared in a response, and denotes whether recursive query support is available in the name server
  bool? ra;

  /// Reserved for future use, always set to 0.
  bool z;

  /// TODO: Find documentation for this field
  bool? ad;

  /// TODO: Find documentation for this field
  bool? cd;

  /// Response code
  RCode? rcode;

  /// Number of entries in the question section.
  int qdcount;

  /// Number of resource records in the answer section.
  int ancount;

  /// Number of name server resource records in the authority records section.
  int nscount;

  /// Number of resource records in the additional records section.
  int arcount;

  get numQuestions => qdcount;
  get numAnswers => ancount;
  get numAuthorities => nscount;
  get numAdditionals => arcount;

  final numBytes = 12;

  Header({
    required this.id,
    required this.qr,
    required this.opcode,
    this.aa,
    required this.tc,
    required this.rd,
    this.ra,
    this.z = false,
    this.ad,
    this.cd,
    this.rcode,
    required this.qdcount,
    required this.ancount,
    required this.nscount,
    required this.arcount,
  });

  static Codec<Header> codec = Codec<Header>(_encode, _decode);

  factory Header.decode(Uint8List buf, {int offset = 0}) =>
      codec.decode(buf, offset: offset).value;

  Uint8List encode({Uint8List? buf, int offset = 0}) =>
      codec.encode(this).value;

  int encodingLength() => numBytes;
}

Encode<Header> _encode = (
  Header header, {
  Uint8List? input,
  int offset = 0,
}) {
  final buf = input ?? Uint8List(12);
  final byteData = ByteData.sublistView(buf);

  byteData.setUint16(offset, header.id, Endian.big);
  offset += 2;

  final flags = (header.qr ? 1 : 0) << 15 |
      (header.opcode.value & 0xF) << 11 |
      (header.aa ?? false ? 1 : 0) << 10 |
      (header.tc ? 1 : 0) << 9 |
      (header.rd ? 1 : 0) << 8 |
      (header.ra ?? false ? 1 : 0) << 7 |
      (header.z ? 1 : 0) << 6 |
      (header.ad ?? false ? 1 : 0) << 5 |
      (header.cd ?? false ? 1 : 0) << 4 |
      (header.rcode?.value ?? 0) & 0xF;

  byteData.setUint16(offset, flags, Endian.big);
  offset += 2;

  byteData.setUint16(offset, header.qdcount, Endian.big);
  offset += 2;
  byteData.setUint16(offset, header.ancount, Endian.big);
  offset += 2;
  byteData.setUint16(offset, header.nscount, Endian.big);
  offset += 2;
  byteData.setUint16(offset, header.arcount, Endian.big);

  return EncodeResult(buf, 12);
};

Decode _decode = (Uint8List buf, {int offset = 0}) {
  if (buf.length < 12) throw Exception('Header must be 12 bytes');

  final byteData = ByteData.sublistView(buf);
  final flags = byteData.getUint16(offset + 2, Endian.big);

  final header = Header(
    id: byteData.getUint16(offset, Endian.big),
    qr: (flags >> 15) & 0x1 == 1,
    opcode: OpCode.fromValue((flags >> 11) & 0xf),
    aa: (flags >> 10) & 0x1 == 1,
    tc: (flags >> 9) & 0x1 == 1,
    rd: (flags >> 8) & 0x1 == 1,
    ra: (flags >> 7) & 0x1 == 1,
    z: (flags >> 6) & 0x1 == 1,
    ad: (flags >> 5) & 0x1 == 1,
    cd: (flags >> 4) & 0x1 == 1,
    rcode: RCode.fromValue(flags & 0xf),
    qdcount: byteData.getUint16(offset + 4, Endian.big),
    ancount: byteData.getUint16(offset + 6, Endian.big),
    nscount: byteData.getUint16(offset + 8, Endian.big),
    arcount: byteData.getUint16(offset + 10, Endian.big),
  );

  return DecodeResult(header, 12);
};
