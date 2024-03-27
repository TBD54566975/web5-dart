class ZBase32 {
  static const String _base32Alphabet = 'ybndrfg8ejkmcpqxot1uwisza345h769';

  static String encode(List<int> data) {
    final StringBuffer result = StringBuffer();
    int bits = 0;
    int bitCount = 0;

    for (int byte in data) {
      bits = (bits << 8) | byte;
      bitCount += 8;

      while (bitCount >= 5) {
        bitCount -= 5;
        final int index = bits >> bitCount;
        bits &= ((1 << bitCount) - 1);
        result.write(_base32Alphabet[index]);
      }
    }

    if (bitCount > 0) {
      bits <<= (5 - bitCount);
      result.write(_base32Alphabet[bits]);
    }

    return result.toString();
  }

  static List<int> decode(String encoded) {
    final List<int> result = [];

    int bits = 0;
    int bitCount = 0;

    for (int i = 0; i < encoded.length; i++) {
      final int value = _base32Alphabet.indexOf(encoded[i]);
      if (value == -1) {
        throw ArgumentError('Invalid character in encoded string');
      }

      bits = (bits << 5) | value;
      bitCount += 5;

      if (bitCount >= 8) {
        bitCount -= 8;
        result.add(bits >> bitCount);
        bits &= ((1 << bitCount) - 1);
      }
    }

    return result;
  }
}
