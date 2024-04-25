import 'dart:typed_data';

abstract interface class Codec<T> {
  EncodeResult encode(T value, {Uint8List? input, int offset});
  DecodeResult<T> decode(Uint8List buf, {int offset});
}

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
