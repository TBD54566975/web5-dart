import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/dns_packet/class.dart';
import 'package:web5/src/dids/did_dht/dns_packet/consts.dart';
import 'package:web5/src/dids/did_dht/dns_packet/name.dart';
import 'package:web5/src/dids/did_dht/dns_packet/type.dart';

class DnsQuestion {
  late DnsName name;
  late DnsType type;
  late DnsClass klass;
  late bool qu; // QU bit flag
  int numBytes = 0;

  DnsQuestion({
    required this.name,
    required this.type,
    required this.klass,
    this.qu = false,
  });

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

  Uint8List encode({Uint8List? buf, int offset = 0}) {
    final originalOffset = offset;

    buf ??= Uint8List(encodingLength());
    final byteData = ByteData.sublistView(buf);

    // Encode the name
    final n = name.encode(buf: buf, offset: offset);
    offset += n.elementSizeInBytes;

    // Write the type
    byteData.setUint16(offset, type.value, Endian.big);
    offset += 2;

    // Write the class, taking into account the QU bit
    final klassValue = qu ? (klass.value | QU_MASK) : klass.value;
    byteData.setUint16(offset, klassValue, Endian.big);
    offset += 2;

    numBytes = offset -
        originalOffset; // Update numBytes to reflect actual length used
    return buf;
  }

  int encodingLength() {
    return name.encodingLength() + 4;
  }
}
