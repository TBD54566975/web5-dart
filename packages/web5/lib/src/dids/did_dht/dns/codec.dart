import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/dns/record_type.dart';

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

typedef Decode = DecodeResult<dynamic> Function(Uint8List buf, {int offset});
typedef Encode<T> = EncodeResult Function(
  T value, {
  Uint8List? input,
  int offset,
});

class Codec<T> {
  Encode<T> encode;
  Decode decode;
  RecordType? type;

  Codec(this.encode, this.decode, {this.type});
}
