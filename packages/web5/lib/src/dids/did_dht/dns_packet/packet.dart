// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:web5/src/crypto.dart';
import 'package:web5/src/dids/bearer_did.dart';
import 'package:web5/src/dids/did_core/did_service.dart';
import 'package:web5/src/dids/did_core/did_verification_method.dart';
import 'package:web5/src/dids/did_dht/dns_packet/answer.dart';
import 'package:web5/src/dids/did_dht/dns_packet/header.dart';
import 'package:web5/src/dids/did_dht/dns_packet/opcode.dart';
import 'package:web5/src/dids/did_dht/dns_packet/question.dart';
import 'package:web5/src/dids/did_dht/dns_packet/type.dart';
import 'package:web5/src/dids/did_dht/registered_did_type.dart';

const int DNS_RECORD_TTL = 7200;
const int DID_DHT_SPECIFICATION_VERSION = 0;

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

  Uint8List encode({Uint8List? buf, int offset = 0}) {
    buf ??= Uint8List(encodingLength());
    final oldOffset = offset;

    // Encode the header
    final h = header.encode(
      buf: buf,
      offset: offset,
    );
    offset += h
        .elementSizeInBytes; // Assuming this method exists and is implemented correctly

    // Directly encode each question
    for (var question in questions) {
      final q = question.encode(
        buf: buf,
        offset: offset,
      );
      offset = q
          .elementSizeInBytes; // Assuming this method exists and is implemented correctly
    }

    // Directly encode each answer
    for (var answer in answers) {
      final a = answer.encode(
        buf: buf,
        offset: offset,
      );
      offset = a
          .elementSizeInBytes; // Assuming this method exists and is implemented correctly
    }

    // Store the number of bytes encoded
    final numBytes = offset - oldOffset;

    // Just a quick sanity check
    if (numBytes != buf.length) {
      return Uint8List.sublistView(buf, 0, numBytes);
    }

    return buf;
  }

  factory DnsPacket.fromDid(BearerDid did) {
    final List<BaseAnswer<String>> dnsAnswerRecords = [];
    final Map<String, String> idLookup = {};
    final List<String> serviceIds = [];
    final List<String> verificationMethodIds = [];

    // Add DNS TXT records if the DID document contains an `alsoKnownAs` property.
    if (did.document.alsoKnownAs != null) {
      dnsAnswerRecords.add(
        BaseAnswer<String>(
          type: DnsType.TXT,
          name: '_aka.did.',
          ttl: DNS_RECORD_TTL,
          data: did.document.alsoKnownAs!.join(','),
        ),
      );
    }

    // Add DNS TXT records if the DID document contains a `controller` property.
    if (did.document.controller != null) {
      String controller;

      if (did.document.controller is List<String>) {
        controller = (did.document.controller as List<String>).join(',');
      } else {
        controller = did.document.controller as String;
      }

      dnsAnswerRecords.add(
        BaseAnswer<String>(
          type: DnsType.TXT,
          name: '_cnt.did.',
          ttl: DNS_RECORD_TTL,
          data: controller,
        ),
      );
    }

    // Add DNS TXT records for each verification method.
    if (did.document.verificationMethod != null) {
      for (var i = 0; i < did.document.verificationMethod!.length; i++) {
        final DidVerificationMethod vm = did.document.verificationMethod![i];

        final String dnsRecordId = 'k$i';
        verificationMethodIds.add(dnsRecordId);

        // Remove fragment prefix, if any.
        final String methodId = vm.id.split('#').last;
        idLookup[methodId] = dnsRecordId;

        final Jwk? publicKey = vm.publicKeyJwk;

        // Use the public key's `crv` property to get the DID DHT key type.
        int keyType;

        // Convert the public key from JWK format to a byte array.
        Uint8List publicKeyBytes;

        switch (publicKey?.crv) {
          case 'Ed25519':
            keyType = 0;
            publicKeyBytes = Ed25519.publicKeyToBytes(publicKey: publicKey!);
            break;
          case 'secp256k1':
            keyType = 1;
            publicKeyBytes = Secp256k1.publicKeyToBytes(publicKey: publicKey!);
            break;
          default:
            throw 'Verification method ${vm.id} contains an unsupported key type: ${publicKey?.crv}';
        }

        // Convert the public key from a byte array to Base64URL format.
        final String publicKeyBase64Url = utf8.decode(publicKeyBytes);
        // Define the data for the DNS TXT record.
        final List<String> txtData = [
          'id=$methodId',
          't=$keyType',
          'k=$publicKeyBase64Url',
        ];

        // Add the controller property, if set to a value other than the Identity Key (DID Subject).
        if (vm.controller != did.document.id) txtData.add('c=${vm.controller}');

        // Add a TXT record for the verification method.
        dnsAnswerRecords.add(
          BaseAnswer<String>(
            type: DnsType.TXT,
            name: '_$dnsRecordId._did.',
            ttl: DNS_RECORD_TTL,
            data: txtData.join(';'),
          ),
        );
      }
    }

    // Add DNS TXT records for each service.
    if (did.document.service != null) {
      for (var i = 0; i < did.document.service!.length; i++) {
        final DidService service = did.document.service![i];
        final String dnsRecordId = 's$i';

        serviceIds.add(dnsRecordId);
        final String id = service.id.split('#').last;

        // Define the data for the DNS TXT record.
        final List<String> txtData = [
          'id=$id',
          'se=${service.serviceEndpoint}',
          't=${service.type}',
        ];

        // Add a TXT record for the service.
        dnsAnswerRecords.add(
          BaseAnswer(
            type: DnsType.TXT,
            name: '_$dnsRecordId._did.',
            data: txtData.join(';'),
          ),
        );
      }
    }

    // Initialize the root DNS TXT record with the DID DHT specification version.
    final List<String> rootRecord = ['v=$DID_DHT_SPECIFICATION_VERSION'];

    // Add verification methods to the root record.
    if (verificationMethodIds.isNotEmpty) {
      rootRecord.add('vm=${verificationMethodIds.join(',')}');
    }

    // Collect the verification method IDs for the given relationship and add to the rootRecord.
    if (did.document.assertionMethod?.isNotEmpty ?? false) {
      rootRecord.add(
        'assertionMethod=${did.document.assertionMethod!.join(',')}',
      );
    }
    if (did.document.authentication?.isNotEmpty ?? false) {
      rootRecord.add(
        'authentication=${did.document.authentication!.join(',')}',
      );
    }
    if (did.document.capabilityDelegation?.isNotEmpty ?? false) {
      rootRecord.add(
        'capabilityDelegation=${did.document.capabilityDelegation!.join(',')}',
      );
    }
    if (did.document.capabilityInvocation?.isNotEmpty ?? false) {
      rootRecord.add(
        'capabilityInvocation=${did.document.capabilityInvocation!.join(',')}',
      );
    }
    if (did.document.keyAgreement?.isNotEmpty ?? false) {
      rootRecord.add(
        'keyAgreement=${did.document.keyAgreement!.join(',')}',
      );
    }

    if (serviceIds.isNotEmpty) {
      rootRecord.add('svc=${serviceIds.join(',')}');
    }

    // If defined, add a DNS TXT record for each registered DID type.
    if (did.metadata.types?.isNotEmpty ?? false) {
      dnsAnswerRecords.add(
        BaseAnswer<String>(
          type: DnsType.TXT,
          name: '_typ._did.',
          ttl: DNS_RECORD_TTL,
          data: 'id=${did.metadata.types!.map((e) => e.value).join(',')}',
        ),
      );
    }

    // Add a DNS TXT record for the root record.
    dnsAnswerRecords.add(
      BaseAnswer(
        type: DnsType.TXT,
        name: '_did.',
        ttl: DNS_RECORD_TTL,
        data: rootRecord.join(';'),
      ),
    );

    // Per the DID DHT specification, the method-specific identifier must be appended as the
    // Origin of all records.
    final String identifier = did.document.id.split(':').last;
    for (final BaseAnswer<String> record in dnsAnswerRecords) {
      record.name += identifier;
    }

    // Create a DNS response packet with the authoritative answer flag set.
    return DnsPacket(
      header: DnsHeader(
        id: 0,
        qr: false,
        opcode: DnsOpCode.QUERY,
        tc: false,
        rd: true,
        qdcount: 0,
        ancount: dnsAnswerRecords.length,
        nscount: 0,
        arcount: 0,
      ),
      questions: [],
      answers: [],
    );
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
