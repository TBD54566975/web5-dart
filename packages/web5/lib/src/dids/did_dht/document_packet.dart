// bridge class that houses logic to go to / from did documents and dns packet

import 'package:web5/src/dids/did_dht/dns/answer.dart';
import 'package:web5/src/dids/did_dht/dns/packet.dart';
import 'package:web5/src/dids/did_dht/dns/rdata.dart';
import 'package:web5/src/dids/did_dht/dns/record_type.dart';
import 'package:web5/src/dids/did_dht/dns/txt_data.dart';
import 'package:web5/src/dids/did_dht/service_record.dart';
import 'package:web5/src/dids/did_dht/vm_record.dart';
import 'package:web5/web5.dart';

class DocumentPacket {
  // will want to store root record inside doc packet
  // precompute a parsed root record, etc
  List<String>? rootRecord;
  Map<String, List<String>> txtMap;
  Map<String, List<String>> relationshipsMap;

  DocumentPacket({
    this.rootRecord,
    Map<String, List<String>>? txtMap,
    Map<String, List<String>>? relationshipsMap,
  })  : txtMap = txtMap ?? {},
        relationshipsMap = relationshipsMap ?? {};

  // TODO: rename this func
  void populateTxtMap(List<Answer<RData>> answers) {
    for (final answer in answers) {
      if (answer.type != RecordType.TXT) {
        continue;
      }

      final txtData = answer.data as TxtData;

      if (answer.name.value.startsWith('_did')) {
        rootRecord = txtData.value;
        continue;
      }

      txtMap[answer.name.value] = txtData.value;
    }
  }

  // TODO: rename this func
  void populateRelationshipsMap(List<String> rootRecord) {
    for (final entry in rootRecord[0].split(';')) {
      final splitEntry = entry.split('=');

      if (splitEntry.length != 2) {
        // TODO: figure out more appopriate resolution error to use.
        throw Exception('invalid DID');
      }

      final [property, values] = splitEntry;
      final splitValues = values.split(',');

      if (!txtEntryNames.contains(property)) {
        continue;
      }

      for (final value in splitValues) {
        relationshipsMap[value] ??= [];
        relationshipsMap[value]!.add(property);
      }
    }
  }

  static Packet toPacket(DidDocument document) {
    final List<Answer<TxtData>> answers = [];
    for (final service in document.service ?? []) {
      final txtRecord = ServiceRecord.toTxtRecord(service);
      answers.add(txtRecord);
    }

    for (final vm in document.verificationMethod ?? []) {
      final txtRecord = VerificationMethodRecord.toTxtRecord(vm);
      answers.add(txtRecord);
    }

    return Packet.create(answers);
  }

  static DidDocument toDidDocument(Packet packet) {
    final List<DidService> services = [];
    final List<DidVerificationMethod> verificationMethods = [];

    for (final answer in packet.answers) {
      if (answer.name.value.startsWith('_s')) {
        final service = ServiceRecord.toDidService(answer as Answer<TxtData>);
        services.add(service);
      } else if (answer.name.value.startsWith('_v')) {
        final vm = VerificationMethodRecord.toDidVerificationMethod(
          answer as Answer<TxtData>,
        );
        verificationMethods.add(vm);
      }
    }

    return DidDocument(
      id: packet.header.id.toString(),
      // TODO: what is the controller here?
      controller: [packet.header.id.toString()],
      service: services,
      verificationMethod: verificationMethods,
    );
  }
}
