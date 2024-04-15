// ignore_for_file: constant_identifier_names

import 'dart:typed_data';

import 'package:web5/src/dids/did_dht/dns/answer.dart';
import 'package:web5/src/dids/did_dht/dns/codec.dart';
import 'package:web5/src/dids/did_dht/dns/header.dart';
import 'package:web5/src/dids/did_dht/dns/question.dart';

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

  factory Packet.decode(List<int> input) {
    final result = PacketCodec.decode(input);
    return result.value;
  }

  Uint8List encode({Uint8List? buf, int offset = 0}) {
    final result = PacketCodec.encode(this, input: buf, offset: offset);
    return result.value;
  }

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

class PacketCodec {
  static DecodeResult<Packet> decode(List<int> input) {
    int offset = 0;
    final bytes = Uint8List.fromList(input);

    final headerResult = HeaderCodec.decode(bytes, offset: offset);
    offset += headerResult.offset;

    final List<Question> questions = [];
    for (var i = 0; i < headerResult.value.numQuestions; i += 1) {
      final questionResult = QuestionCodec.decode(bytes, offset: offset);
      questions.add(questionResult.value);

      offset += questionResult.offset;
    }

    final List<Answer> answers = [];
    for (var i = 0; i < headerResult.value.numAnswers; i += 1) {
      final answerResult = AnswerCodec.decode(bytes, offset: offset);
      answers.add(answerResult.value);
      offset += answerResult.offset;
    }

    final List<Answer> authorities = [];
    for (var i = 0; i < headerResult.value.numAuthorities; i += 1) {
      final answerResult = AnswerCodec.decode(bytes, offset: offset);
      authorities.add(answerResult.value);
      offset += answerResult.offset;
    }

    final List<Answer> additionals = [];
    for (var i = 0; i < headerResult.value.numAdditionals; i += 1) {
      final answerResult = AnswerCodec.decode(bytes, offset: offset);
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
      offset,
    );
  }

  static EncodeResult encode(Packet packet,
      {Uint8List? input, int offset = 0}) {
    final buf = input ?? Uint8List(packet.encodingLength());
    final oldOffset = offset;

    final headerResult = HeaderCodec.encode(
      packet.header,
      input: buf,
      offset: offset,
    );
    offset += headerResult.offset;

    for (final question in packet.questions) {
      final questionResult = QuestionCodec.encode(
        question,
        input: buf,
        offset: offset,
      );
      offset = questionResult.offset;
    }

    for (var answer in packet.answers) {
      final answerResult = AnswerCodec.encode(
        answer,
        input: buf,
        offset: offset,
      );
      offset = answerResult.offset;
    }

    return EncodeResult(buf, offset - oldOffset);
  }
}
