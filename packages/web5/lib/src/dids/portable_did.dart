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

  factory PortableDid.fromJson(Map<String, dynamic> json) {
    return PortableDid(
      uri: json['uri'],
      document: DidDocument.fromJson(json['document']),
      privateKeys:
          (json['privateKeys'] as List).map((e) => Jwk.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uri': uri,
      'document': document.toJson(),
      'privateKeys': privateKeys.map((e) => e.toJson()).toList(),
    };
  }
}
