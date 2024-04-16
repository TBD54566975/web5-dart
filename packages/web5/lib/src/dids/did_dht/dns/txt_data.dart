import 'dart:convert';
import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/dns/codec.dart';
import 'package:web5/src/dids/did_dht/dns/rdata.dart';

class TxtData implements RData {
  final List<String> value;

  TxtData(this.value);

  factory TxtData.decode(Uint8List buf, {int offset = 0}) {
    final result = TxtDataCodec.decode(buf, offset: offset);
    return result.value;
  }

  Uint8List encode() {
    return TxtDataCodec.encode(this).value;
  }

  @override
  int encodingLength() {
    int length = 2;
    for (var buf in value) {
      length += utf8.encode(buf).length + 1;
    }

    return length;
  }
}

class TxtDataCodec {
  static EncodeResult encode(
    TxtData data, {
    Uint8List? input,
    int offset = 0,
  }) {
    final buf = input ?? Uint8List(data.encodingLength());
    final byteData = ByteData.sublistView(buf);

    final originalOffset = offset;
    offset += 2; // Reserve space for the total length

    for (String str in data.value) {
      final encodedStr = utf8.encode(str);
      if (encodedStr.length > 255) {
        throw FormatException('Individual TXT record exceeds 255 bytes');
      }
      buf[offset++] = encodedStr.length; // Write the length of the string
      buf.setRange(offset, offset + encodedStr.length, encodedStr);
      offset += encodedStr.length;
    }

    byteData.setUint16(originalOffset, offset - originalOffset - 2, Endian.big);

    return EncodeResult(buf, offset - originalOffset);
  }

  static DecodeResult<TxtData> decode(Uint8List buf, {int offset = 0}) {
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

    return DecodeResult(TxtData(data), offset - originalOffset);
  }
}
