import 'package:web5/src/dids/did_dht/dns/answer.dart';
import 'package:web5/src/dids/did_dht/dns/txt_data.dart';
import 'package:web5/web5.dart';

// TODO: fill these out next
class ServiceRecord {
  factory ServiceRecord.fromService(DidService service) {
    throw UnimplementedError();
  }

  factory ServiceRecord.fromRecord(Answer<TxtData> record) {
    throw UnimplementedError();
  }

  DidService toService() {
    throw UnimplementedError();
  }
}
