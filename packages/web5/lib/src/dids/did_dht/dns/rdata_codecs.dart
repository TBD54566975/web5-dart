import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/dns/codec.dart';
import 'package:web5/src/dids/did_dht/dns/rdata.dart';
import 'package:web5/src/dids/did_dht/dns/record_type.dart';
import 'package:web5/src/dids/did_dht/dns/txt_data.dart';

class RDataCodecs {
  static final Map<RecordType, Codec> _codecs = {
    RecordType.TXT: TxtData.codec,
  };

  static EncodeResult encode(
    RecordType type,
    RData data, {
    Uint8List? input,
    int offset = 0,
  }) {
    final codec =
        _codecs[type] ?? (throw Exception('No codec found for type $type'));
    return codec.encode(data, input: input, offset: offset);
  }

  static DecodeResult decode<T>(
    RecordType type,
    Uint8List buf, {
    int offset = 0,
  }) {
    final codec =
        _codecs[type] ?? (throw Exception('No codec found for type $type'));
    return codec.decode(buf, offset: offset);
  }
}
