import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/dns/codec.dart';
import 'package:web5/src/dids/did_dht/dns/name.dart';
import 'package:web5/src/dids/did_dht/dns/record_class.dart';
import 'package:web5/src/dids/did_dht/dns/record_type.dart';
import 'package:web5/src/dids/did_dht/dns_packet/consts.dart';

class Question {
  late RecordName name;
  late RecordType type;
  late RecordClass klass;
  late bool qu;
  int numBytes = 0;

  Question({
    required this.name,
    required this.type,
    required this.klass,
    this.qu = false,
  });

  Question._();

  static Codec<Question> codec = Codec<Question>(_encode, _decode);

  factory Question.decode(Uint8List buf, int offset) =>
      Question.codec.decode(buf, offset: offset).value;

  Uint8List encode({Uint8List? buf, int offset = 0}) =>
      Question.codec.encode(this, input: buf, offset: offset).value;

  int encodingLength() {
    return name.encodingLength() + 4;
  }
}

Encode<Question> _encode = (
  Question question, {
  Uint8List? input,
  int offset = 0,
}) {
  final buf = input ??= Uint8List(question.encodingLength());
  final originalOffset = offset;

  final n = RecordName.codec.encode(question.name, input: buf, offset: offset);
  offset += n.offset;

  ByteData.view(buf.buffer).setUint16(offset, question.type.value, Endian.big);

  offset += 2;

  final klassValue =
      question.qu ? (question.klass.value | QU_MASK) : question.klass.value;
  ByteData.view(buf.buffer).setUint16(offset, klassValue, Endian.big);

  offset += 2;

  return EncodeResult(input, offset - originalOffset);
};

Decode _decode = (Uint8List buf, {int offset = 0}) {
  final originalOffset = offset;

  final nameResult = RecordName.codec.decode(buf, offset: offset);
  offset += nameResult.offset;

  final byteData = ByteData.sublistView(buf);

  final rawType = byteData.getUint16(offset, Endian.big);
  final type = RecordType.fromValue(rawType);
  offset += type.numBytes;

  int rawKlass = byteData.getUint16(offset, Endian.big);
  var klass = RecordClass.fromValue(rawKlass);
  offset += klass.numBytes;

  final question = Question._();
  question.name = nameResult.value;
  question.type = type;

  final qu = (rawKlass & QU_MASK) != 0;

  if (qu) {
    rawKlass &= NOT_QU_MASK;
    klass = RecordClass.fromValue(rawKlass);
  }

  question.klass = klass;
  question.qu = qu;

  return DecodeResult(question, offset - originalOffset);
};
