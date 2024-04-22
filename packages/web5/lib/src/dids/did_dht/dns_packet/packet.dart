// ignore_for_file: constant_identifier_names

import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/dns_packet/answer.dart';
import 'package:web5/src/dids/did_dht/dns_packet/codec.dart';
import 'package:web5/src/dids/did_dht/dns_packet/header.dart';
import 'package:web5/src/dids/did_dht/dns_packet/opcode.dart';
import 'package:web5/src/dids/did_dht/dns_packet/question.dart';

const int DNS_RECORD_TTL = 7200;
const int DID_DHT_SPECIFICATION_VERSION = 0;

class Packet {
  Header header;
  List<Question> questions;
  List<Answer> answers;
  List<Answer> authorities;
  List<Answer> additionals;

  Packet({
    required this.header,
    required this.questions,
    required this.answers,
    required this.authorities,
    required this.additionals,
  });

  // TODO: fix this create method
  static Packet create(List<Answer> answers) {
    return Packet(
      header: Header(
        id: 0,
        qr: false,
        opcode: OpCode.NOTIFY,
        tc: false,
        rd: false,
        qdcount: 0,
        ancount: answers.length,
        nscount: 0,
        arcount: 0,
      ),
      questions: [],
      answers: answers,
      authorities: [],
      additionals: [],
    );
  }

  static final codec = _PacketCodec();

  factory Packet.decode(Uint8List buf, int offset) =>
      codec.decode(buf, offset: offset).value;

  Uint8List encode({Uint8List? buf, int offset = 0}) =>
      codec.encode(this, input: buf, offset: offset).value;

  int encodingLength() {
    int length = header.encodingLength();
    for (var question in questions) {
      length += question.encodingLength();
    }
    for (var answer in answers) {
      length += answer.encodingLength();
    }
    return length;
  }
}

class _PacketCodec implements Codec<Packet> {
  @override
  EncodeResult encode(
    Packet packet, {
    Uint8List? input,
    int offset = 0,
  }) {
    final buf = input ?? Uint8List(packet.encodingLength());
    final oldOffset = offset;

    final headerResult = Header.codec.encode(
      packet.header,
      input: buf,
      offset: offset,
    );
    offset += headerResult.offset;

    for (final question in packet.questions) {
      final questionResult = Question.codec.encode(
        question,
        input: buf,
        offset: offset,
      );
      offset = questionResult.offset;
    }

    for (var answer in packet.answers) {
      final answerResult = Answer.codec.encode(
        answer,
        input: buf,
        offset: offset,
      );
      offset = answerResult.offset;
    }

    return EncodeResult(buf, offset - oldOffset);
  }

  @override
  DecodeResult<Packet> decode(Uint8List buf, {int offset = 0}) {
    final originalOffset = offset;

    final headerResult = Header.codec.decode(buf, offset: offset);
    offset += headerResult.offset;

    final List<Question> questions = [];
    for (var i = 0; i < headerResult.value.numQuestions; i += 1) {
      final questionResult = Question.codec.decode(buf, offset: offset);
      questions.add(questionResult.value);

      offset += questionResult.offset;
    }

    final List<Answer> answers = [];
    for (var i = 0; i < headerResult.value.numAnswers; i += 1) {
      final answerResult = Answer.codec.decode(buf, offset: offset);
      answers.add(answerResult.value);
      offset += answerResult.offset;
    }

    final List<Answer> authorities = [];
    for (var i = 0; i < headerResult.value.numAuthorities; i += 1) {
      final answerResult = Answer.codec.decode(buf, offset: offset);
      authorities.add(answerResult.value);
      offset += answerResult.offset;
    }

    final List<Answer> additionals = [];
    for (var i = 0; i < headerResult.value.numAdditionals; i += 1) {
      final answerResult = Answer.codec.decode(buf, offset: offset);
      additionals.add(answerResult.value);
      offset += answerResult.offset;
    }

    return DecodeResult(
      Packet(
        header: headerResult.value,
        questions: questions,
        answers: answers,
        authorities: authorities,
        additionals: additionals,
      ),
      offset - originalOffset,
    );
  }
}
