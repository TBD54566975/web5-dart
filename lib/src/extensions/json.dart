import 'dart:convert';
import 'dart:typed_data';

import 'package:web5/src/encoders.dart';

/// Extension on [JsonCodec] to provide additional encoding functionalities.
///
/// This extension adds methods to the [JsonCodec] class to support converting
/// JSON objects to byte arrays and Base64 URL encoded strings.
extension Encoders on JsonCodec {
  /// Converts a JSON object into a byte array.
  ///
  /// This method first encodes the given [object] into a JSON string and then
  /// converts that string into a list of bytes using UTF-8 encoding.
  ///
  ///
  /// Returns a [List<int>] representing the byte array.
  Uint8List toBytes(Object object) {
    final stringified = encode(object);

    return utf8.encoder.convert(stringified);
  }

  /// Converts a JSON object into a Base64 URL encoded string.
  ///
  /// This method first converts the given [object] into a byte array and then
  /// encodes that array into a Base64 URL encoded string. The [padding]
  /// parameter determines whether the encoded string includes padding.
  ///
  ///
  /// Returns a [String] representing the Base64 URL encoded value.
  String toBase64Url(Object object) {
    final bytes = toBytes(object);

    return Base64Url.encode(bytes);
  }

  dynamic fromBase64Url(String input) {
    final bytes = Base64Url.decode(input);
    final stringified = utf8.decode(bytes);

    return json.decode(stringified);
  }
}
