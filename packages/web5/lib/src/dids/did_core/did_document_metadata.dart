import 'package:web5/src/dids/did_dht/registered_did_type.dart';

/// contains metadata about the DID document contained in the didDocument
/// property. This metadata typically does not change between invocations of
/// the resolve and resolveRepresentation functions unless the DID document
/// changes, as it represents metadata about the DID document.
///
/// [Specification Reference](https://www.w3.org/TR/did-core/#dfn-diddocumentmetadata)
class DidDocumentMetadata {
  /// timestamp of the Create operation. The value of the property MUST be a
  /// string formatted as an XML Datetime normalized to UTC 00:00:00 and
  /// without sub-second decimal precision. For example: 2020-12-20T19:17:47Z.
  final String? created;

  /// timestamp of the last Update operation for the document version which was
  /// resolved. The value of the property MUST follow the same formatting rules
  /// as the created property. The updated property is omitted if an Update
  /// operation has never been performed on the DID document. If an updated
  /// property exists, it can be the same value as the created property
  /// when the difference between the two timestamps is less than one second.
  final String? updated;

  /// If a DID has been deactivated, DID document metadata MUST include this
  /// property with the boolean value true. If a DID has not been deactivated,
  /// this property is OPTIONAL, but if included, MUST have the boolean value
  /// false.
  final bool? deactivated;

  /// indicates the version of the last Update operation for the document version
  /// which was resolved.
  final String? versionId;

  /// indicates the timestamp of the next Update operation. The value of the
  /// property MUST follow the same formatting rules as the created property.
  final String? nextUpdate;

  /// if the resolved document version is not the latest version of the document.
  /// It indicates the timestamp of the next Update operation. The value of the
  /// property MUST follow the same formatting rules as the created property.
  final String? nextVersionId;

  /// A DID method can define different forms of a DID that are logically
  /// equivalent. An example is when a DID takes one form prior to registration
  /// in a verifiable data registry and another form after such registration.
  /// In this case, the DID method specification might need to express one or
  /// more DIDs that are logically equivalent to the resolved DID as a property
  /// of the DID document. This is the purpose of the equivalentId property.
  final String? equivalentId;

  /// The canonicalId property is identical to the equivalentId property except:
  ///   * it is associated with a single value rather than a set
  ///   * the DID is defined to be the canonical ID for the DID subject within
  ///     the scope of the containing DID document.
  final String? canonicalId;

  final List<DidDhtRegisteredDidType>? types;

  const DidDocumentMetadata({
    this.created,
    this.updated,
    this.deactivated,
    this.versionId,
    this.nextUpdate,
    this.nextVersionId,
    this.equivalentId,
    this.canonicalId,
    this.types,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DidDocumentMetadata &&
        other.created == created &&
        other.updated == updated &&
        other.deactivated == deactivated &&
        other.versionId == versionId &&
        other.nextUpdate == nextUpdate &&
        other.nextVersionId == nextVersionId &&
        other.equivalentId == equivalentId &&
        other.canonicalId == canonicalId;
  }

  @override
  int get hashCode {
    return Object.hash(
      created,
      updated,
      deactivated,
      versionId,
      nextUpdate,
      nextVersionId,
      equivalentId,
      canonicalId,
    );
  }
}
