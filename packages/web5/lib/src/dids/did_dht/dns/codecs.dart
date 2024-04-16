import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/dns/codec.dart';
import 'package:web5/src/dids/did_dht/dns/name.dart';
import 'package:web5/src/dids/did_dht/dns/record_type.dart';

class Codecs {
  static Map<RecordType, Codec> codecs = {
    RecordName.codec.type: RecordName.codec,
  };

  static DecodeResult decode<T>(
    RecordType type,
    Uint8List buf, {
    int offset = 0,
  }) {
    final codec = codecs[type];
    if (codec == null) {
      throw Exception('No codec found for type $type');
    }

    return codec.decode(buf, offset: offset);
  }

  static EncodeResult encode<T>(
    RecordType type,
    T value, {
    Uint8List? input,
    int offset = 0,
  }) {
    final codec = codecs[type];
    if (codec == null) {
      throw Exception('No codec found for type $type');
    }

    return codec.encode(value, input: input, offset: offset);
  }
}
