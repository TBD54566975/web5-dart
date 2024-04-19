import 'package:web5/src/dids/did_dht/dns/answer.dart';
import 'package:web5/src/dids/did_dht/dns/txt_data.dart';

// TODO: why does this need to be a separate class
class RootRecord {
  static const Set<String> txtEntryNames = {
    'v',
    'vm',
    'auth',
    'asm',
    'inv',
    'del',
    'srv',
  };

  // TODO: fix this
  static Answer<TxtData>? getRootRecord(List<Answer<TxtData>> answers) {
    for (final answer in answers) {
      if (answer.name.value.startsWith('_did')) {
        return answer;
      }
    }
    return null;
  }
}
