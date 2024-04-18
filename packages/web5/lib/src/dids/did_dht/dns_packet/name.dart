import 'dart:convert';
import 'dart:typed_data';

class DnsName {
  final String value;
  int get numBytes => utf8.encode(value).length + 2;

  DnsName({required this.value});

  factory DnsName.decode(Uint8List buf, int offset, {bool mail = false}) {
    int oldOffset = offset;
    int totalLength = 0;
    int consumedBytes = 0;
    final List<String> list = [];
    bool jumped = false;

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

        String label = utf8.decode(buf.sublist(offset, offset + len));

        if (mail) {
          label = label.replaceAll('.', r'\.');
        }

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

    return DnsName(value: decodedName);
    // return DnsName(decodedName, consumedBytes);
  }

  Uint8List encode({Uint8List? buf, int offset = 0}) {
    buf ??= Uint8List(encodingLength());

    // Strip leading and trailing dots
    final n = value.replaceAll(RegExp(r'^\.|\.$'), '');
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

    buf[offset++] = 0;

    return buf;
  }

  int encodingLength() {
    if (value == '.' || value == '..') return 1;
    return utf8.encode(value.replaceAll(RegExp(r'^\.|\.$'), '')).length + 2;
  }
}
