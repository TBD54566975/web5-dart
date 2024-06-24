/// A metadata structure consisting of values relating to the results of the
/// DID resolution process which typically changes between invocations of the
/// resolve and resolveRepresentation functions, as it represents data about
/// the resolution process itself
///
/// [Specification Reference](https://www.w3.org/TR/did-core/#dfn-didresolutionmetadata)
class DidResolutionMetadata {
  /// The Media Type of the returned didDocumentStream. This property is
  /// REQUIRED if resolution is successful and if the resolveRepresentation
  /// function was called
  final String? contentType;

  /// The error code from the resolution process. This property is REQUIRED
  /// when there is an error in the resolution process. The value of this
  /// property MUST be a single keyword ASCII string. The possible property
  /// values of this field SHOULD be registered in the
  /// [DID Specification Registries](https://www.w3.org/TR/did-spec-registries/#error)
  final String? error;

  DidResolutionMetadata({
    this.contentType,
    this.error,
  });

  bool isEmpty() {
    return toJson().isEmpty;
  }

  Map<String, dynamic> toJson() {
    final json = {
      'contentType': contentType,
      'error': error,
    };

    json.removeWhere((key, value) => value == null);

    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DidResolutionMetadata &&
        other.contentType == contentType &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(contentType, error);
}
