import 'package:web5/src/dids/did_dht/dns_packet.dart';

/// [Relevant Spec Text](https://did-dht.com/#root-record)
class RootRecord {
  List<String> vm;
  List<String> srv;
  List<String> inv;
  List<String> del;
  List<String> auth;
  List<String> agm;
  List<String> asm;

  RootRecord({
    this.vm = const [],
    this.asm = const [],
    this.srv = const [],
    this.inv = const [],
    this.del = const [],
    this.auth = const [],
    this.agm = const [],
  });

  addVmRecordName(String vmRecordName) {
    vm.add(vmRecordName);
  }

  addAsmRecordName(String asmRecordName) {
    asm.add(asmRecordName);
  }

  addInvRecordName(String invRecordName) {
    inv.add(invRecordName);
  }

  addDelRecordName(String delRecordName) {
    del.add(delRecordName);
  }

  addAuthRecordName(String authRecordName) {
    auth.add(authRecordName);
  }

  addAgmRecordName(String agmRecordName) {
    agm.add(agmRecordName);
  }

  addSrvRecordName(String srvRecordName) {
    srv.add(srvRecordName);
  }

  Answer<TxtData> toTxtRecord(String didId) {
    final parts = [
      if (vm.isNotEmpty) 'vm=${vm.join(',')}',
      if (asm.isNotEmpty) 'asm=${asm.join(',')}',
      if (inv.isNotEmpty) 'inv=${inv.join(',')}',
      if (del.isNotEmpty) 'del=${del.join(',')}',
      if (auth.isNotEmpty) 'auth=${auth.join(',')}',
      if (agm.isNotEmpty) 'agm=${agm.join(',')}',
      if (srv.isNotEmpty) 'srv=${srv.join(',')}',
    ].join(';');

    final txtData = TxtData([parts]);
    // TODO: make convenience TxtRecord class
    return Answer<TxtData>(
      type: RecordType.TXT,
      klass: RecordClass.IN,
      name: RecordName('_did.$didId'),
      data: txtData,
      ttl: 7200,
    );
  }

  static RootRecord fromTxtRecord(Answer<TxtData> txtRecord) {
    final rData = txtRecord.data.value.first;
    final parts = rData.split(';');

    final rootRecord = RootRecord();

    for (final part in parts) {
      if (!part.contains('=')) {
        throw Exception('Invalid root record format');
      }

      final split = part.split('=');
      if (split.length != 2) {
        throw Exception('Invalid root record format');
      }

      final key = split[0];
      final value = split[1];

      switch (key) {
        case 'vm':
          rootRecord.vm = value.split(',');
          break;
        case 'srv':
          rootRecord.srv = value.split(',');
          break;
        case 'inv':
          rootRecord.inv = value.split(',');
          break;
        case 'del':
          rootRecord.del = value.split(',');
          break;
        case 'auth':
          rootRecord.auth = value.split(',');
          break;
        case 'agm':
          rootRecord.agm = value.split(',');
          break;
        default:
          throw Exception('Invalid root record key');
      }
    }

    return rootRecord;
  }
}
