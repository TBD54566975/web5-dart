import 'dart:typed_data';

import 'package:tbdex/src/dns_packet/answer.dart';
import 'package:tbdex/src/dns_packet/header.dart';
import 'package:tbdex/src/dns_packet/question.dart';

class DnsPacket {
  DnsHeader header;
  List<DnsQuestion> questions;
  List<DnsAnswer> answers;

  DnsPacket({
    required this.header,
    required this.questions,
    required this.answers,
  });

  factory DnsPacket.decode(List<int> input) {
    int offset = 0;
    final bytes = Uint8List.fromList(input);

    final header = DnsHeader.decode(bytes, offset);
    offset += header.numBytes;

    final List<DnsQuestion> questions = [];
    for (var i = 0; i < header.numQuestions; i += 1) {
      final question = DnsQuestion.decode(bytes, offset);
      questions.add(question);

      offset += question.numBytes;
    }

    final List<DnsAnswer> answers = [];
    for (var i = 0; i < header.numAnswers; i += 1) {
      print('offset $offset');
      final answer = DnsAnswer.decode(bytes, offset);
      answers.add(answer);
      offset += answer.numBytes;
    }

    final List<DnsAnswer> authorities = [];
    for (var i = 0; i < header.numAuthorities; i += 1) {
      final answer = DnsAnswer.decode(bytes, offset);
      authorities.add(answer);

      offset += answer.numBytes;
    }

    final List<DnsAnswer> additionals = [];
    for (var i = 0; i < header.numAdditionals; i += 1) {
      final answer = DnsAnswer.decode(bytes, offset);
      additionals.add(answer);

      offset += answer.numBytes;
    }

    return DnsPacket(header: header, questions: questions, answers: answers);
  }
}
