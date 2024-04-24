import 'dart:convert';
import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/dns_packet/codec.dart';

class RecordName {
  final String value;

  RecordName(this.value);

  static final codec = _NameCodec();

  factory RecordName.decode(Uint8List buf, {int offset = 0}) =>
      codec.decode(buf).value;

  Uint8List encode() => codec.encode(this).value;

  int encodingLength() {
    if (value == '.' || value == '..') return 1;
    return utf8.encode(value.replaceAll(RegExp(r'^\.|\.$'), '')).length + 2;
  }
}

class _NameCodec implements Codec<RecordName> {
  @override
  EncodeResult encode(
    RecordName data, {
    Uint8List? input,
    int offset = 0,
  }) {
    final buf = input ?? Uint8List(data.encodingLength());
    final oldOffset = offset;
    // Strip leading and trailing dots
    final n = data.value.replaceAll(RegExp(r'^\.|\.$'), '');
    if (n.isNotEmpty) {
      final list = n.split('.');
      for (var label in list) {
        final encodedLabel = utf8.encode(label);
        buf[offset] = encodedLabel.length; // Length byte
        offset++;
        buf.setRange(offset, offset + encodedLabel.length, encodedLabel);
        offset += encodedLabel.length;
      }
    }

    buf[offset++] = 0; // Null terminator for DNS record

    return EncodeResult(buf, offset - oldOffset);
  }

  @override
  DecodeResult<RecordName> decode(Uint8List buf, {int offset = 0}) {
    int oldOffset = offset;
    int totalLength = 0;
    int consumedBytes = 0;
    bool jumped = false;
    final List<String> list = [];

    while (true) {
      if (offset >= buf.length) {
        throw Exception('Cannot decode name (buffer overflow)');
      }

      final len = buf[offset++];
      consumedBytes += jumped ? 0 : 1;

      if (len == 0) {
        break;
      } else if ((len & 0xc0) == 0) {
        if (offset + len > buf.length) {
          throw Exception('Cannot decode name (buffer overflow)');
        }

        totalLength += len + 1;
        if (totalLength > 254) {
          throw Exception('Cannot decode name (name too long)');
        }

        final label = utf8.decode(buf.sublist(offset, offset + len));

        list.add(label);
        offset += len;
        consumedBytes += jumped ? 0 : len;
      } else if ((len & 0xc0) == 0xc0) {
        if (offset >= buf.length) {
          throw Exception('Cannot decode name (buffer overflow)');
        }

        final jumpOffset = ((len & 0x3f) << 8) | buf[offset++];
        if (jumpOffset >= oldOffset) {
          throw Exception('Cannot decode name (bad pointer)');
        }

        offset = jumpOffset;
        oldOffset = jumpOffset;
        consumedBytes += jumped ? 0 : 1;
        jumped = true;
      } else {
        throw Exception('Cannot decode name (bad label)');
      }
    }

    final decodedName = list.isEmpty ? '.' : list.join('.');

    return DecodeResult(RecordName(decodedName), consumedBytes);
  }
}
