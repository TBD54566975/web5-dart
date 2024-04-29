import 'package:web5/src/dids/did_dht/dns_packet.dart';

/// [Relevant Spec Text](https://did-dht.com/#root-record)
class RootRecord {
  String v;
  List<String> vm;
  List<String> svc;
  List<String> inv;
  List<String> del;
  List<String> auth;
  List<String> agm;
  List<String> asm;

  RootRecord({
    String? v,
    List<String>? vm,
    List<String>? svc,
    List<String>? inv,
    List<String>? del,
    List<String>? auth,
    List<String>? asm,
    List<String>? agm,
  })  : v = v ?? '0',
        vm = vm ?? [],
        svc = svc ?? [],
        inv = inv ?? [],
        del = del ?? [],
        auth = auth ?? [],
        asm = asm ?? [],
        agm = agm ?? [];

  addVmRecordName(int idx) {
    vm.add('k$idx');
  }

  addAsmRecordName(int idx) {
    asm.add('k$idx');
  }

  addInvRecordName(int idx) {
    inv.add('k$idx');
  }

  addDelRecordName(int idx) {
    del.add('k$idx');
  }

  addAuthRecordName(int idx) {
    auth.add('k$idx');
  }

  addAgmRecordName(int idx) {
    agm.add('k$idx');
  }

  addSvcRecordName(int idx) {
    svc.add('s$idx');
  }

  Answer<TxtData> toTxtRecord(String did) {
    final parts = [
      if (vm.isNotEmpty) 'vm=${vm.join(',')}',
      if (asm.isNotEmpty) 'asm=${asm.join(',')}',
      if (inv.isNotEmpty) 'inv=${inv.join(',')}',
      if (del.isNotEmpty) 'del=${del.join(',')}',
      if (auth.isNotEmpty) 'auth=${auth.join(',')}',
      if (agm.isNotEmpty) 'agm=${agm.join(',')}',
      if (svc.isNotEmpty) 'svc=${svc.join(',')}',
    ].join(';');

    // TODO: make convenience TxtRecord class
    return Answer<TxtData>(
      type: RecordType.TXT,
      klass: RecordClass.IN,
      name: RecordName('_did.$did.'),
      data: TxtData([parts]),
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
        case 'v':
          rootRecord.v = value;
          break;
        case 'vm':
          rootRecord.vm = value.split(',');
          break;
        case 'svc':
          rootRecord.svc = value.split(',');
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
        case 'asm':
          rootRecord.asm = value.split(',');
          break;
        default:
          throw Exception('Invalid root record key: $key');
      }
    }

    return rootRecord;
  }
}
