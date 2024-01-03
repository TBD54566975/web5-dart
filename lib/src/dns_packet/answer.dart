import 'dart:typed_data';

import 'package:tbdex/src/dns_packet/type.dart';
import 'package:tbdex/src/dns_packet/name.dart';
import 'package:tbdex/src/dns_packet/rdata.dart';
import 'package:tbdex/src/dns_packet/class.dart';
import 'package:tbdex/src/dns_packet/consts.dart';
import 'package:tbdex/src/dns_packet/opt_data.dart';
import 'package:tbdex/src/dns_packet/txt_data.dart';

/// Represents an answer section in a DNS packet.
class DnsAnswer {
  /// The domain name to which this resource record pertains.
  late DnsName name;

  /// The type of the resource record. Specifies the meaning of the data in the RData field.
  late DnsType type;

  /// The class of the data in the RData field.
  late DnsClass klass;

  /// The specific data for this resource record, according to its type.
  late RData data;

  /// The Time-To-Live of the resource record. This value is the number of seconds
  /// that the resource record may be cached before it should be discarded.
  late int ttl;

  /// A flag indicating whether the cache flush bit is set for this record.
  late bool flush;

  /// For OPT records, this field specifies the maximum UDP payload size.
  late int udpPayloadSize;

  /// For OPT records, this field specifies the extended RCODE.
  late int extendedRcode;

  /// For OPT records, this field specifies the EDNS version.
  late int ednsVersion;

  /// For OPT records, this field specifies the EDNS flags.
  late int flags;

  /// For OPT records, this field indicates whether the DNSSEC OK bit is set.
  late bool flagDo;

  /// Options for OPT records, dynamically determined based on the specific type of option.
  late dynamic options;

  /// The total number of bytes consumed in decoding this DNS answer.
  int numBytes = 0;

  /// Decodes a [DnsAnswer] from a byte buffer [buf] starting at the given [offset].
  ///
  /// Throws [FormatException] if the buffer data cannot be decoded into a valid DNS answer.
  DnsAnswer.decode(Uint8List buf, int offset) {
    final originalOffset = offset;

    name = DnsName.decode(buf, offset);
    offset += name.numBytes;

    final byteData = ByteData.sublistView(buf);

    final rawType = byteData.getUint16(offset, Endian.big);
    type = DnsType.fromValue(rawType);
    offset += 2;

    if (type == DnsType.OPT) {
      udpPayloadSize = byteData.getUint16(offset + 2, Endian.big);
      extendedRcode = byteData.getUint8(offset + 4);
      ednsVersion = byteData.getUint8(offset + 5);

      flags = byteData.getUint16(offset + 6, Endian.big);
      flagDo = (flags >> 15) & 0x1 == 1;

      options = DnsOptData.decode(buf, offset + 8);

      offset += (8 + options.numBytes).toInt();
    } else {
      final rawDnsClass = byteData.getUint16(offset, Endian.big);
      klass = DnsClass.fromValue(rawDnsClass & NOT_FLUSH_MASK);

      flush = (rawDnsClass & FLUSH_MASK) != 0;
      offset += 2;

      ttl = byteData.getUint32(offset, Endian.big);
      offset += 4;

      switch (type) {
        case DnsType.TXT:
          data = DnsTxtData.decode(buf, offset);
          offset += data.numBytes;
          break;
        default:
          break;
      }
    }

    numBytes = offset - originalOffset;
  }
}
