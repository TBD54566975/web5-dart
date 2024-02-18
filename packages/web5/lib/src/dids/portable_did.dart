import 'package:web5/src/crypto.dart';
import 'package:web5/src/dids/did_core.dart';

class PortableDid {
  String uri;
  DidDocument document;
  List<Jwk> privateKeys;

  PortableDid({
    required this.uri,
    required this.document,
    this.privateKeys = const [],
  });
}
