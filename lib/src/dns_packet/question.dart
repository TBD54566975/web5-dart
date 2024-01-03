import 'dart:typed_data';

import 'package:tbdex/src/dns_packet/class.dart';
import 'package:tbdex/src/dns_packet/consts.dart';
import 'package:tbdex/src/dns_packet/name.dart';
import 'package:tbdex/src/dns_packet/type.dart';

class DnsQuestion {
  late DnsName name;
  late DnsType type;
  late DnsClass klass;
  late bool qu; // QU bit flag
  int numBytes = 0;

  DnsQuestion.decode(Uint8List buf, int offset) {
    final originalOffset = offset;

    name = DnsName.decode(buf, offset);
    offset += name.numBytes;

    final byteData = ByteData.sublistView(buf);

    final rawType = byteData.getUint16(offset, Endian.big);
    final type = DnsType.fromValue(rawType);
    offset += type.numBytes;

    int rawKlass = byteData.getUint16(offset, Endian.big);
    klass = DnsClass.fromValue(rawKlass);
    offset += klass.numBytes;

    qu = (rawKlass & QU_MASK) != 0;
    if (qu) {
      rawKlass &= NOT_QU_MASK;
      klass = DnsClass.fromValue(rawKlass);
    }

    numBytes = offset - originalOffset;
  }

  int encodingLength(DnsQuestion question) {
    return question.name.encodingLength() + 4;
  }
}
