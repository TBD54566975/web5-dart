import 'dart:typed_data';

class ZBase32 {
  static const String _alphabet = 'ybndrfg8ejkmcpqxot1uwisza345h769';
  static const int _bitsPerByte = 8;
  static const int _bitsPerBase32Char = 5;
  static const int _maskBase32 = 0x1F; // Mask for extracting 5 bits
  static const int _maskByte = 0xFF; // Mask for byte within an integer
  static const int _decoderSize =
      128; // Size of the decoder array based on ASCII range
  static final List<int> _decoder = List.filled(_decoderSize, -1);

  // Initialize decoder array with indices of valid zbase32 characters.
  static void _initializeDecoder() {
    for (int i = 0; i < _alphabet.length; i++) {
      _decoder[_alphabet.codeUnitAt(i)] = i;
    }
  }

  static String encode(List<int> data) {
    if (data.isEmpty) return '';

    int buffer = 0;
    int bufferLength = 0;
    final result = StringBuffer();

    for (int b in data) {
      buffer = (buffer << _bitsPerByte) + (b & _maskByte);
      bufferLength += _bitsPerByte;
      while (bufferLength >= _bitsPerBase32Char) {
        final charIndex =
            (buffer >> (bufferLength - _bitsPerBase32Char)) & _maskBase32;
        result.write(_alphabet[charIndex]);
        bufferLength -= _bitsPerBase32Char;
      }
    }

    if (bufferLength > 0) {
      final charIndex =
          (buffer << (_bitsPerBase32Char - bufferLength)) & _maskBase32;
      result.write(_alphabet[charIndex]);
    }

    return result.toString();
  }

  static Uint8List decode(String data) {
    if (data.isEmpty) return Uint8List(0);

    _initializeDecoder(); // Ensure the decoder is initialized before decoding

    int buffer = 0;
    int bufferLength = 0;
    final List<int> result = [];

    for (int i = 0; i < data.length; i++) {
      final c = data.codeUnitAt(i);
      final index = _decoder[c];
      if (index == -1) {
        throw FormatException('Invalid zbase32 character: ${data[i]}');
      }

      buffer = (buffer << _bitsPerBase32Char) + index;
      bufferLength += _bitsPerBase32Char;
      while (bufferLength >= _bitsPerByte) {
        final b = (buffer >> (bufferLength - _bitsPerByte)) & _maskByte;
        result.add(b);
        bufferLength -= _bitsPerByte;
      }
    }

    return Uint8List.fromList(result);
  }
}
