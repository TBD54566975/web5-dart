import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/dns/codec.dart';
import 'package:web5/src/dids/did_dht/dns/rdata.dart';
import 'package:web5/src/dids/did_dht/dns/record_type.dart';
import 'package:web5/src/dids/did_dht/dns/txt_data.dart';

class RdataCodecs {
  static final Map<RecordType, Codec<RData>> _rdataCodecs = {
    TxtData.codec.type!: TxtData.codec,
  };

  static DecodeResult decode<T>(
    RecordType type,
    Uint8List buf, {
    int offset = 0,
  }) {
    final codec = _rdataCodecs[type];
    if (codec == null) {
      throw Exception('No codec found for type $type');
    }

    return codec.decode(buf, offset: offset);
  }

  static EncodeResult encode<T extends RData>(
    RecordType type,
    T value, {
    Uint8List? input,
    int offset = 0,
  }) {
    final codec = _rdataCodecs[type];
    if (codec == null || codec is! Codec<T>) {
      throw Exception('No codec found for type $type or type mismatch');
    }

    print('codec runtime type: ${codec.runtimeType}');
    print('value runtime type: ${value.runtimeType}');

    final y =
        TxtData.codec.encode(value as TxtData, input: input, offset: offset);
    print('y: $y');
    final x = codec.encode(value, input: input, offset: offset);

    return x;

    // return codec.encode(value, input: input, offset: offset);
  }
}
