import 'dart:typed_data';

class EncodeResult {
  final Uint8List value;
  final int offset;

  EncodeResult(this.value, this.offset);
}

class DecodeResult<T> {
  final T value;
  final int offset;

  DecodeResult(this.value, this.offset);
}
