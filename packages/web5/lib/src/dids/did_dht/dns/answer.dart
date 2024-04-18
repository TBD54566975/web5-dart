import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/dns/codec.dart';
import 'package:web5/src/dids/did_dht/dns/rdata_codecs.dart';
import 'package:web5/src/dids/did_dht/dns/consts.dart';
import 'package:web5/src/dids/did_dht/dns/name.dart';
import 'package:web5/src/dids/did_dht/dns/opt_data.dart';
import 'package:web5/src/dids/did_dht/dns/rdata.dart';
import 'package:web5/src/dids/did_dht/dns/record_class.dart';
import 'package:web5/src/dids/did_dht/dns/record_type.dart';

/// Represents an answer section in a DNS packet.
class Answer<T extends RData> {
  /// The domain name to which this resource record pertains.
  late RecordName name;

  /// The type of the resource record. Specifies the meaning of the data in the RData field.
  late RecordType type;

  /// The class of the data in the RData field.
  late RecordClass klass;

  /// The specific data for this resource record, according to its type.
  late T data;

  /// The Time-To-Live of the resource record. This value is the number of seconds
  /// that the resource record may be cached before it should be discarded.
  late int ttl;

  /// A flag indicating whether the cache flush bit is set for this record.
  late bool flush;

  /// For OPT records, this field specifies the maximum UDP payload size.
  late int? udpPayloadSize;

  /// For OPT records, this field specifies the extended RCODE.
  late int? extendedRcode;

  /// For OPT records, this field specifies the EDNS version.
  late int? ednsVersion;

  /// For OPT records, this field specifies the EDNS flags.
  late int? flags;

  /// For OPT records, this field indicates whether the DNSSEC OK bit is set.
  late bool? flagDo;

  /// Options for OPT records, dynamically determined based on the specific type of option.
  late dynamic options;

  Answer({
    required this.name,
    required this.type,
    required this.klass,
    required this.data,
    required this.ttl,
    this.flush = false,
    this.udpPayloadSize,
    this.extendedRcode,
    this.ednsVersion,
    this.flags,
    this.flagDo,
    this.options,
  });

  Answer._();

  static final codec = _AnswerCodec();

  /// Decodes a [Answer] from a byte buffer [buf] starting at the given [offset].
  ///
  /// Throws [FormatException] if the buffer data cannot be decoded into a valid DNS answer.
  factory Answer.decode(Uint8List buf, int offset) =>
      codec.decode(buf, offset: offset).value as Answer<T>;

  Uint8List encode({Uint8List? buf, int offset = 0}) =>
      codec.encode(this, input: buf, offset: offset).value;

  int encodingLength() {
    return name.encodingLength() + 8 + data.encodingLength();
  }
}

class _AnswerCodec implements Codec<Answer> {
  @override
  EncodeResult encode(
    Answer answer, {
    Uint8List? input,
    int offset = 0,
  }) {
    final buf = input ?? Uint8List(answer.encodingLength());
    final oldOffset = offset;

    final n = RecordName.codec.encode(answer.name, input: buf, offset: offset);
    offset += n.offset;

    ByteData.view(buf.buffer).setUint16(offset, answer.type.value, Endian.big);

    if (answer.type == RecordType.OPT) {
      if (answer.name.value != '.') {
        throw Exception('OPT name must be root.');
      }
      ByteData.view(buf.buffer)
          .setUint16(offset, answer.udpPayloadSize!, Endian.big);

      buf[offset + 4] = answer.extendedRcode!;
      buf[offset + 5] = answer.ednsVersion!;

      ByteData.view(buf.buffer)
          .setUint16(offset + 6, answer.flags ?? 0, Endian.big);

      offset += 8;
      // TODO: need OptDataCodec here
      offset += answer.options.encode(buf, offset) as int;
    } else {
      final klassValue = answer.flush ? FLUSH_MASK : answer.klass.value;
      ByteData.view(buf.buffer).setUint16(offset + 2, klassValue, Endian.big);

      ByteData.view(buf.buffer).setUint32(offset + 4, answer.ttl, Endian.big);

      offset += 8;

      final result = RDataCodecs.encode(
        answer.type,
        answer.data,
        input: buf,
        offset: offset,
      );
      offset += result.offset;
    }

    return EncodeResult(buf, offset - oldOffset);
  }

  @override
  DecodeResult<Answer> decode(Uint8List buf, {int offset = 0}) {
    final originalOffset = offset;

    final nameResult = RecordName.codec.decode(buf, offset: offset);
    offset += nameResult.offset;

    final byteData = ByteData.sublistView(buf);

    final rawType = byteData.getUint16(offset, Endian.big);
    final type = RecordType.fromValue(rawType);
    offset += 2;

    final answer = Answer._();
    answer.name = nameResult.value;
    answer.type = type;

    if (type == RecordType.OPT) {
      answer.udpPayloadSize = byteData.getUint16(offset + 2, Endian.big);
      answer.extendedRcode = byteData.getUint8(offset + 4);
      answer.ednsVersion = byteData.getUint8(offset + 5);

      answer.flags = byteData.getUint16(offset + 6, Endian.big);
      answer.flagDo = (answer.flags! >> 15) & 0x1 == 1;

      answer.options = OptionData.decode(buf, offset + 8);

      offset += (8 + answer.options.numBytes).toInt();
    } else {
      final rawDnsClass = byteData.getUint16(offset, Endian.big);
      answer.klass = RecordClass.fromValue(rawDnsClass & NOT_FLUSH_MASK);

      answer.flush = (rawDnsClass & FLUSH_MASK) != 0;
      offset += 2;

      answer.ttl = byteData.getUint32(offset, Endian.big);
      offset += 4;

      final result = RDataCodecs.decode(type, buf, offset: offset);
      answer.data = result.value;
      offset += result.offset;
    }

    return DecodeResult(answer, offset - originalOffset);
  }
}
