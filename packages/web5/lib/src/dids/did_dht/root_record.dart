import 'package:web5/src/dids/did_dht/dns_packet.dart';

class RootRecord {
  List<String> vmRecordNames;
  List<String> srvRecordNames;
  List<String> invRecordNames;
  List<String> delRecordNames;
  List<String> authRecordNames;
  List<String> agmRecordNames;
  List<String> asmRecordNames;

  RootRecord({
    this.vmRecordNames = const [],
    this.asmRecordNames = const [],
    this.srvRecordNames = const [],
    this.invRecordNames = const [],
    this.delRecordNames = const [],
    this.authRecordNames = const [],
    this.agmRecordNames = const [],
  });

  addVmRecordName(String vmRecordName) {
    vmRecordNames.add(vmRecordName);
  }

  addAsmRecordName(String asmRecordName) {
    asmRecordNames.add(asmRecordName);
  }

  addInvRecordName(String invRecordName) {
    invRecordNames.add(invRecordName);
  }

  addDelRecordName(String delRecordName) {
    delRecordNames.add(delRecordName);
  }

  addAuthRecordName(String authRecordName) {
    authRecordNames.add(authRecordName);
  }

  addAgmRecordName(String agmRecordName) {
    agmRecordNames.add(agmRecordName);
  }

  addSrvRecordName(String srvRecordName) {
    srvRecordNames.add(srvRecordName);
  }

  Answer<TxtData> toTxtRecord() {
    final rData = [
      'vm=${vmRecordNames.join(',')}',
      'asm=${asmRecordNames.join(',')}',
      'inv=${invRecordNames.join(',')}',
      'del=${delRecordNames.join(',')}',
      'auth=${authRecordNames.join(',')}',
      'agm=${agmRecordNames.join(',')}',
      'srv=${srvRecordNames.join(',')}',
    ].join(';');

    final txtData = TxtData([rData]);
    // TODO: make convenience TxtRecord class
    return Answer<TxtData>(
      type: RecordType.TXT,
      klass: RecordClass.IN,
      name: RecordName('TODO_FILL_OUT'),
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
          rootRecord.vmRecordNames = value.split(',');
          break;
        case 'srv':
          rootRecord.srvRecordNames = value.split(',');
          break;
        case 'inv':
          rootRecord.invRecordNames = value.split(',');
          break;
        case 'del':
          rootRecord.delRecordNames = value.split(',');
          break;
        case 'auth':
          rootRecord.authRecordNames = value.split(',');
          break;
        case 'agm':
          rootRecord.agmRecordNames = value.split(',');
          break;
        default:
          throw Exception('Invalid root record key');
      }
    }

    return rootRecord;
  }
}
