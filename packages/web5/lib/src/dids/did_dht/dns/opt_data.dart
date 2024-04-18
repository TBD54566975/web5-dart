import 'dart:typed_data';

class OptionData {
  final List<Option> options;
  final int numBytes;

  OptionData._(this.options, this.numBytes);

  factory OptionData.decode(Uint8List buf, int offset) {
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
    return OptionData._(options, consumedBytes);
  }

  int get encodingLength {
    return 2 + options.fold(0, (sum, option) => sum + option.numBytes);
  }
}

class Option {
  late OptionCode code;
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
    code = OptionCode.fromValue(rawCode);

    final len = byteData.getUint16(offset);
    offset += 2;

    data = buf.sublist(offset, offset + len);

    // Handling specific option types
    switch (code) {
      case OptionCode.CLIENT_SUBNET:
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

      case OptionCode.TCP_KEEPALIVE:
        if (len > 0) {
          timeout = byteData.getUint16(offset);
          offset += 2;
        }
        break;

      case OptionCode.KEY_TAG:
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

// ignore_for_file: constant_identifier_names
enum OptionCode {
  LLQ(1, 'LLQ'),
  UL(2, 'UL'),
  NSID(3, 'NSID'),
  DAU(5, 'DAU'),
  DHU(6, 'DHU'),
  N3U(7, 'N3U'),
  CLIENT_SUBNET(8, 'CLIENT_SUBNET'),
  EXPIRE(9, 'EXPIRE'),
  COOKIE(10, 'COOKIE'),
  TCP_KEEPALIVE(11, 'TCP_KEEPALIVE'),
  PADDING(12, 'PADDING'),
  CHAIN(13, 'CHAIN'),
  KEY_TAG(14, 'KEY_TAG'),
  DEVICEID(26946, 'DEVICEID'),
  UNKNOWN(-1, 'UNKNOWN'); // Default for unknown or undefined types

  final int value;
  final String name;

  const OptionCode(this.value, this.name);

  static OptionCode fromValue(int value) {
    return OptionCode.values.firstWhere(
      (opt) => opt.value == value,
      orElse: () => OptionCode.UNKNOWN, // Default or a suitable fallback
    );
  }

  static OptionCode fromName(String name) {
    if (name.startsWith('OPTION_')) {
      final value = int.tryParse(name.substring(7)) ?? -1;
      return fromValue(value);
    }
    return OptionCode.values.firstWhere(
      (opt) => opt.name.toUpperCase() == name.toUpperCase(),
      orElse: () => OptionCode.UNKNOWN, // Default or a suitable fallback
    );
  }
}
