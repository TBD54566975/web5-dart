import 'dart:convert';

import 'package:web5/src/dids/did_core/did_dereference_metadata.dart';
import 'package:web5/src/dids/did_core/did_document_metadata.dart';
import 'package:web5/src/dids/did_core/did_resource.dart';

class DidDereferenceResult {
  DidDereferenceMetadata dereferencingMetadata;
  DidResource? contentStream;
  DidDocumentMetadata contentMetadata;

  DidDereferenceResult({
    DidDereferenceMetadata? dereferencingMetadata,
    this.contentStream,
    DidDocumentMetadata? contentMetadata,
  })  : dereferencingMetadata =
            dereferencingMetadata ?? DidDereferenceMetadata(),
        contentMetadata = contentMetadata ?? DidDocumentMetadata();

  factory DidDereferenceResult.fromJson(Map<String, dynamic> json) {
    return DidDereferenceResult(
      dereferencingMetadata:
          DidDereferenceMetadata.fromJson(json['dereferencingMetadata']),
      contentStream: json['contentStream'],
      contentMetadata: json['contentMetadata'],
    );
  }

  factory DidDereferenceResult.withError(String error) {
    return DidDereferenceResult(
      dereferencingMetadata: DidDereferenceMetadata(error: error),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dereferencingMetadata': dereferencingMetadata.toJson(),
      'contentStream': contentStream?.toJson(),
      'contentMetadata': contentMetadata.toJson(),
    };
  }

  @override
  String toString() => json.encode(toJson());

  bool hasError() {
    return dereferencingMetadata.error != null;
  }
}
