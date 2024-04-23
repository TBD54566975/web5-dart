// bridge class that houses logic to go to / from did documents and dns packet

import 'package:web5/src/dids/did_dht/dns_packet.dart';
import 'package:web5/src/dids/did_dht/root_record.dart';
import 'package:web5/src/dids/did_dht/service_record.dart';
import 'package:web5/src/dids/did_dht/vm_record.dart';
import 'package:web5/web5.dart';

class DocumentPacket {
  static Packet toPacket(DidDocument document) {
    final rootRecord = RootRecord();
    final List<Answer<TxtData>> answers = [];

    final vmRecordMap = {};

    final verificationMethods = document.verificationMethod ?? [];
    for (var i = 0; i < verificationMethods.length; i++) {
      final vm = verificationMethods[i];
      final txtRecord = VerificationMethodRecord.toTxtRecord(i, vm);

      answers.add(txtRecord);
      rootRecord.addVmRecordName(txtRecord.name.value);

      vmRecordMap[vm.id] = txtRecord.name.value;
    }

    final assertionMethods = document.assertionMethod ?? [];
    for (final am in assertionMethods) {
      final vmRecordName = vmRecordMap[am];
      if (vmRecordName != null) {
        rootRecord.addAsmRecordName(vmRecordName);
      }
    }

    final authMethods = document.authentication ?? [];
    for (final am in authMethods) {
      final vmRecordName = vmRecordMap[am];
      if (vmRecordName != null) {
        rootRecord.addAuthRecordName(vmRecordName);
      }
    }

    final capabilityDelegations = document.capabilityDelegation ?? [];
    for (final cd in capabilityDelegations) {
      final vmRecordName = vmRecordMap[cd];
      if (vmRecordName != null) {
        rootRecord.addDelRecordName(vmRecordName);
      }
    }

    final capabilityInvocations = document.capabilityInvocation ?? [];
    for (final ci in capabilityInvocations) {
      final vmRecordName = vmRecordMap[ci];
      if (vmRecordName != null) {
        rootRecord.addInvRecordName(vmRecordName);
      }
    }

    final agmMethods = document.keyAgreement ?? [];
    for (final agm in agmMethods) {
      final vmRecordName = vmRecordMap[agm];
      if (vmRecordName != null) {
        rootRecord.addAgmRecordName(vmRecordName);
      }
    }

    final serviceRecords = document.service ?? [];
    for (var i = 0; i < serviceRecords.length; i++) {
      final service = serviceRecords[i];
      final txtRecord = ServiceRecord.toTxtRecord(i, service);

      answers.add(txtRecord);
      rootRecord.addSrvRecordName(txtRecord.name.value);
    }

    return Packet.create(answers);
  }
}
