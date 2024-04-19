// bridge class that houses logic to go to / from did documents and dns packet

import 'package:web5/src/dids/did_dht/dns/answer.dart';
import 'package:web5/src/dids/did_dht/dns/packet.dart';
import 'package:web5/src/dids/did_dht/dns/txt_data.dart';
import 'package:web5/src/dids/did_dht/service_record.dart';
import 'package:web5/src/dids/did_dht/vm_record.dart';
import 'package:web5/web5.dart';

class DocumentPacket {
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
