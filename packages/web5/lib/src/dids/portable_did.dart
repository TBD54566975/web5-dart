import 'package:web5/src/crypto.dart';
import 'package:web5/src/dids/did_core.dart';

class PortableDid {
  String uri;
  DidDocument document;
  late List<Jwk> privateKeys;

  PortableDid({
    required this.uri,
    required this.document,
    List<Jwk>? privateKeys,
  }) : privateKeys = privateKeys ?? [];

  factory PortableDid.fromMap(Map<String, dynamic> map) {
    return PortableDid(
      uri: map['uri'],
      document: DidDocument.fromJson(map['document']),
      privateKeys:
          (map['privateKeys'] as List).map((e) => Jwk.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> get map {
    return {
      'uri': uri,
      'document': document.toJson(),
      'privateKeys': privateKeys.map((e) => e.toJson()).toList(),
    };
  }
}
