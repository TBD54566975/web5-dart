import 'dart:typed_data';
import 'package:convert/convert.dart';

extension Converters on BigInt {
  Uint8List toBytes() {
    final hexVal = toRadixString(16).padLeft(32, "0");
    return Uint8List.fromList(hex.decode(hexVal));
  }
}
