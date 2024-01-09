import 'dart:convert';

/// A metadata structure consisting of values relating to the results of the
/// DID URL dereferencing process. This structure is REQUIRED, and in the case
/// of an error in the dereferencing process, this MUST NOT be empty. Properties
///  defined by this specification are in 7.2.2 DID URL Dereferencing Metadata.
/// If the dereferencing is not successful, this structure MUST contain an error
///  property describing the error.
///
/// [Specification Reference](https://www.w3.org/TR/did-core/#did-url-dereferencing-metadata)
class DidDereferenceMetadata {
  /// The Media Type of the returned contentStream
  String? contentType;

  /// The error code from the dereferencing process. This property is REQUIRED
  /// when there is an error in the dereferencing process.
  String? error;

  /// used to store properties specific to individual DID methods. properties
  /// within this map will be included at the top level when json serialized
  Map<String, dynamic> additionalProperties;

  DidDereferenceMetadata({
    this.contentType,
    this.error,
    Map<String, dynamic>? additionalProperties,
  }) : additionalProperties = additionalProperties ?? {};

  factory DidDereferenceMetadata.fromJson(Map<String, dynamic> json) {
    return DidDereferenceMetadata(
      contentType: json['contentType'],
      error: json['error'],
      additionalProperties: json
        ..remove('contentType')
        ..remove('error'),
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'contentType': contentType,
      'error': error,
      ...additionalProperties,
    };

    json.removeWhere((key, value) => value == null);

    return json;
  }

  @override
  String toString() => json.encode(toJson());
}
