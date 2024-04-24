import 'dart:typed_data';

import 'package:web5/src/dids/did_core.dart';
import 'package:web5/src/dids/did_dht/converters/service_converter.dart';
import 'package:web5/src/dids/did_dht/converters/vm_converter.dart';
import 'package:web5/src/dids/did_dht/dns_packet.dart';
import 'package:web5/src/dids/did_dht/root_record.dart';

/// Class that houses methods to convert a [DidDocument] to a [DnsPacket]
/// and vice versa.
class DidDocumentConverter {
  /// Converts a [DidDocument] to a [DnsPacket].
  static DnsPacket convertDidDocument(DidDocument document) {
    final rootRecord = RootRecord();
    final List<Answer<TxtData>> answers = [];

    final vmRecordMap = {};

    final verificationMethods = document.verificationMethod ?? [];
    for (var i = 0; i < verificationMethods.length; i++) {
      final vm = verificationMethods[i];
      final txtRecord =
          VerificationMethodConverter.convertVerificationMethod(i, vm);

      answers.add(txtRecord);
      rootRecord.addVmRecordName(i);

      vmRecordMap[vm.id] = i;
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
      final txtRecord = ServiceRecordConverter.convertService(i, service);

      answers.add(txtRecord);
      rootRecord.addSrvRecordName(i);
    }

    answers.insert(0, rootRecord.toTxtRecord(document.id));

    return DnsPacket.create(answers);
  }

  static DidDocument convertDnsPacket(String did, DnsPacket dnsPacket) {
    final didDocument = DidDocument(id: did);

    final purposesMap = {};
    RootRecord? rootRecord;

    for (final answer in dnsPacket.answers) {
      final txtRecord = answer as Answer<TxtData>;

      if (txtRecord.name.value == '_did.$did') {
        rootRecord = RootRecord.fromTxtRecord(txtRecord);
      } else if (txtRecord.name.value.startsWith('_k')) {
        final vm = VerificationMethodConverter.convertTxtRecord(did, txtRecord);
        didDocument.addVerificationMethod(vm);

        final delim = txtRecord.name.value.indexOf('.', 3);
        final recordName = txtRecord.name.value.substring(0, delim);
        purposesMap[vm.id] = recordName;
      } else if (txtRecord.name.value.startsWith('_s')) {
        final service = ServiceRecordConverter.convertTxtRecord(did, txtRecord);
        didDocument.addService(service);
      }
    }

    for (final recordName in rootRecord!.asm) {
      final vmId = purposesMap[recordName];
      didDocument.addVerificationPurpose(
        VerificationPurpose.assertionMethod,
        vmId,
      );
    }

    for (final recordName in rootRecord.auth) {
      final vmId = purposesMap[recordName];
      didDocument.addVerificationPurpose(
        VerificationPurpose.authentication,
        vmId,
      );
    }

    for (final recordName in rootRecord.del) {
      final vmId = purposesMap[recordName];
      didDocument.addVerificationPurpose(
        VerificationPurpose.capabilityDelegation,
        vmId,
      );
    }

    for (final recordName in rootRecord.inv) {
      final vmId = purposesMap[recordName];
      didDocument.addVerificationPurpose(
        VerificationPurpose.capabilityInvocation,
        vmId,
      );
    }

    for (final recordName in rootRecord.agm) {
      final vmId = purposesMap[recordName];
      didDocument.addVerificationPurpose(
        VerificationPurpose.keyAgreement,
        vmId,
      );
    }

    return didDocument;
  }
}
