import 'dart:convert';
import 'dart:typed_data';

/// Extension [EncoderPadding] on [Base64Encoder].
///
/// This extension provides additional functionality to the standard
/// Base64 encoding process. It includes the [convertNoPadding] method
/// that performs Base64 encoding without padding.
extension EncoderPadding on Base64Encoder {
  /// Converts a list of integers to a Base64 encoded string without padding.
  ///
  /// The [convertNoPadding] method takes a list of integers [input], which
  /// represents the bytes to encode. It then encodes the input using Base64
  /// encoding and removes any padding ('=') characters from the resulting
  /// encoded string.
  ///
  /// This is useful when the padding is not required or desired in the
  /// encoded output e.g. JWK, JWS, JWT. Reference:
  /// https://datatracker.ietf.org/doc/id/draft-jones-json-web-key-01.html#base64urllogic
  ///
  /// Example:
  /// ```dart
  /// final encoder = Base64Encoder();
  /// final noPaddingEncoded = encoder.convertNoPadding([72, 101, 108, 108]);
  /// ```
  String convertNoPadding(List<int> input) {
    final converted = convert(input);

    return converted.replaceAll('=', '');
  }
}

extension DecoderPadding on Base64Decoder {
  Uint8List convertNoPadding(String input) {
    final missingPadding = (4 - input.length % 4) % 4;
    final paddedInput = input + '=' * missingPadding;

    return convert(paddedInput);
  }
}
