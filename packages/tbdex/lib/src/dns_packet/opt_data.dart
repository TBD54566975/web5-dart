import 'dart:typed_data';
import 'package:tbdex/src/dns_packet/option_code.dart';

class DnsOptData {
  final List<Option> options;
  final int numBytes;

  DnsOptData._(this.options, this.numBytes);

  factory DnsOptData.decode(Uint8List buf, int offset) {
    final int originalOffset = offset;
    final ByteData byteData = ByteData.sublistView(buf);

    int rdlen = byteData.getUint16(offset);
    offset += 2;

    final List<Option> options = [];
    while (rdlen > 0) {
      final Option option = Option.decode(buf, offset);
      options.add(option);
      offset += option.numBytes;
      rdlen -= option.numBytes;
    }

    final int consumedBytes = offset - originalOffset;
    return DnsOptData._(options, consumedBytes);
  }

  int get encodingLength {
    return 2 + options.fold(0, (sum, option) => sum + option.numBytes);
  }
}

class Option {
  late DnsOptionCode code;
  late Uint8List data;
  int numBytes = 0;

  // Additional fields for specific option types
  int? family;
  int? sourcePrefixLength;
  int? scopePrefixLength;
  List<int>? ip; // Assuming you have a class to handle IP operations
  int? timeout;
  List<int>? tags;

  Option.decode(Uint8List buf, int offset) {
    final originalOffset = offset;
    final byteData = ByteData.sublistView(buf);

    final rawCode = byteData.getUint16(offset);
    offset += 2;
    code = DnsOptionCode.fromValue(rawCode);

    final len = byteData.getUint16(offset);
    offset += 2;

    data = buf.sublist(offset, offset + len);

    // Handling specific option types
    switch (code) {
      case DnsOptionCode.CLIENT_SUBNET:
        family = byteData.getUint16(offset);
        offset += 2;

        sourcePrefixLength = buf[offset++];
        scopePrefixLength = buf[offset++];
        final padded = Uint8List((family == 1) ? 4 : 16);

        // Copy the relevant bytes into the padded array
        for (int i = 0; i < len - 4 && offset + i < buf.length; i++) {
          padded[i] = buf[offset + i];
        }

        ip = padded;
        offset += len - 4;
        break;

      case DnsOptionCode.TCP_KEEPALIVE:
        if (len > 0) {
          timeout = byteData.getUint16(offset);
          offset += 2;
        }
        break;

      case DnsOptionCode.KEY_TAG:
        tags = [];
        for (int i = 0; i < len; i += 2) {
          tags!.add(byteData.getUint16(offset));
          offset += 2;
        }
        break;

      default:
        break;
    }

    numBytes = offset - originalOffset;
  }
}
