import 'dart:typed_data';

abstract interface class RData {
  int get numBytes;

  Uint8List encode();
}
