import 'package:web5/src/dids/did.dart';
import 'package:web5/src/dids/did_core.dart';
import 'package:web5/src/dids/did_dht/dns_packet.dart';
import 'package:web5/src/dids/did_dht/root_record.dart';
import 'package:web5/src/dids/did_dht/converters/vm_converter.dart';
import 'package:web5/src/dids/did_dht/converters/service_converter.dart';

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
      rootRecord.addSvcRecordName(i);
    }

    final methodSpecificId = document.id.split('did:dht:').last;
    answers.insert(0, rootRecord.toTxtRecord(methodSpecificId));

    return DnsPacket.create(answers);
  }

  static DidDocument convertDnsPacket(Did did, DnsPacket dnsPacket) {
    final didDocument = DidDocument(id: did.uri);

    final purposesMap = {};
    RootRecord? rootRecord;

    for (final answer in dnsPacket.answers) {
      if (answer.type != RecordType.TXT) {
        continue;
      }

      // lame but necessary. can't use as Answer<TxtData> because in Dart,
      // even though TxtData is a subtype of RData, Answer<TxtData>
      // is not considered a subtype of Answer<RData> because generic types are
      //invariant. This means that even if B is a subtype of A, Generic<B>
      // is not considered a subtype of Generic<A>
      final txtData = answer.data as TxtData;
      final txtRecord = Answer<TxtData>(
        name: answer.name,
        type: answer.type,
        klass: answer.klass,
        ttl: answer.ttl,
        data: txtData,
      );

      if (answer.name.value == '_did.${did.id}') {
        rootRecord = RootRecord.fromTxtRecord(txtRecord);
      } else if (txtRecord.name.value.startsWith('_k')) {
        final vm =
            VerificationMethodConverter.convertTxtRecord(did.uri, txtRecord);
        didDocument.addVerificationMethod(vm);

        final delim = txtRecord.name.value.indexOf('.', 3);
        final recordName = txtRecord.name.value.substring(1, delim);
        purposesMap[recordName] = vm.id;
      } else if (txtRecord.name.value.startsWith('_s')) {
        final service =
            ServiceRecordConverter.convertTxtRecord(did.uri, txtRecord);
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
