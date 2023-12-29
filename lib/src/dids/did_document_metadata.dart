/// contains metadata about the DID document contained in the didDocument
/// property. This metadata typically does not change between invocations of
/// the resolve and resolveRepresentation functions unless the DID document
/// changes, as it represents metadata about the DID document.
///
/// [Specification Reference](https://www.w3.org/TR/did-core/#dfn-diddocumentmetadata)
class DidDocumentMetadata {
  final String? created;
  final String? updated;
  final bool? deactivated;
  final String? versionId;
  final String? nextUpdate;
  final String? nextVersionId;
  final String? equivalentId;
  final String? canonicalId;

  DidDocumentMetadata({
    this.created,
    this.updated,
    this.deactivated,
    this.versionId,
    this.nextUpdate,
    this.nextVersionId,
    this.equivalentId,
    this.canonicalId,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'created': created,
      'updated': updated,
      'deactivated': deactivated,
      'versionId': versionId,
      'nextUpdate': nextUpdate,
      'nextVersionId': nextVersionId,
      'equivalentId': equivalentId,
      'canonicalId': canonicalId,
    };

    json.removeWhere((key, value) => value == null);

    return json;
  }
}
