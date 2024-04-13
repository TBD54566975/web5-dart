import 'dart:convert';
import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/dns_packet/rdata.dart';

class DnsTxtData implements RData {
  final List<String> value;

  @override
  int numBytes;

  DnsTxtData(this.value, this.numBytes);

  factory DnsTxtData.decode(Uint8List buf, int offset) {
    final originalOffset = offset;
    int remaining = ByteData.sublistView(buf).getUint16(offset, Endian.big);
    offset += 2;

    final List<String> data = [];
    while (remaining > 0) {
      final len = buf[offset++];
      remaining--;
      if (remaining < len) {
        throw Exception('Buffer overflow');
      }

      final text = String.fromCharCodes(buf.sublist(offset, offset + len));
      data.add(text);
      offset += len;
      remaining -= len;
    }

    final numBytes = offset - originalOffset;
    return DnsTxtData(data, numBytes);
  }

  @override
  Uint8List encode({Uint8List? buf, int offset = 0}) {
    buf ??= Uint8List(encodingLength());
    final byteData = ByteData.sublistView(buf);

    final originalOffset = offset;
    offset += 2; // Reserve space for the total length

    for (String str in value) {
      final encodedStr = utf8.encode(str);
      if (encodedStr.length > 255) {
        throw FormatException('Individual TXT record exceeds 255 bytes');
      }
      buf[offset++] = encodedStr.length; // Write the length of the string
      buf.setRange(offset, offset + encodedStr.length, encodedStr);
      offset += encodedStr.length;
    }

    byteData.setUint16(originalOffset, offset - originalOffset - 2, Endian.big);

    return buf;
  }

  int encodingLength() {
    int length = 2;
    for (var buf in value) {
      length += utf8.encode(buf).length + 1;
    }
    return length;
  }
}
