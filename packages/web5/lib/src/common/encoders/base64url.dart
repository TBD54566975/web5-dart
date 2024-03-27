import 'dart:convert';
import 'dart:typed_data';

class Base64Url {
  static final _codec = Base64Codec.urlSafe();

  static String encode(List<int> input) {
    final encoded = _codec.encode(input);

    return encoded.replaceAll('=', '');
  }

  static Uint8List decode(String input) {
    final missingPadding = (4 - input.length % 4) % 4;
    final paddedInput = input + '=' * missingPadding;

    return _codec.decode(paddedInput);
  }
}
