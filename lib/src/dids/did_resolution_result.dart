import 'package:tbdex/src/dids/did_document.dart';
import 'package:tbdex/src/dids/did_document_metadata.dart';
import 'package:tbdex/src/dids/did_resolution_metadata.dart';

/// A class representing the result of a DID (Decentralized Identifier)
/// resolution.
///
/// This class encapsulates the metadata and document information obtained as
/// a result of resolving a DID. It includes the resolution metadata, the DID
/// document (if available), and the document metadata.
///
/// The `DidResolutionResult` can be initialized with specific metadata and
/// document information, or it can be created with default values if no
/// specific information is provided.
///
/// Instances of this class can also be converted to a JSON representation
/// suitable for transmission or storage.
///
/// Example Usage:
/// ```dart
/// var resolutionResult = DidResolutionResult(
///   didResolutionMetadata: customResolutionMetadata,
///   didDocument: customDidDocument,
///   didDocumentMetadata: customDocumentMetadata,
/// );
/// ```
///
/// [Specification Reference](https://www.w3.org/TR/did-core/#resolution)
class DidResolutionResult {
  /// The metadata associated with the DID resolution process.
  ///
  /// This includes information about the resolution process itself, such as any errors
  /// that occurred. If not provided in the constructor, it defaults to an empty
  /// `DidResolutionMetadata`.
  final DidResolutionMetadata didResolutionMetadata;

  /// The resolved DID document, if available.
  ///
  /// This is the document that represents the resolved state of the DID. It may be `null`
  /// if the DID could not be resolved or if the document is not available.
  final DidDocument? didDocument;

  /// The metadata associated with the DID document.
  ///
  /// This includes information about the document such as when it was created and
  /// any other relevant metadata. If not provided in the constructor, it defaults to an
  /// empty `DidDocumentMetadata`.
  final DidDocumentMetadata didDocumentMetadata;

  /// Constructs a [DidResolutionResult] with optional parameters for resolution metadata
  /// and document metadata. If these parameters are not provided, default values are used.
  ///
  /// [didResolutionMetadata] - Optional. The metadata associated with the DID resolution.
  /// [didDocument] - Optional. The resolved DID document.
  /// [didDocumentMetadata] - Optional. The metadata associated with the DID document.
  DidResolutionResult({
    DidResolutionMetadata? didResolutionMetadata,
    this.didDocument,
    DidDocumentMetadata? didDocumentMetadata,
  })  : didResolutionMetadata =
            didResolutionMetadata ?? DidResolutionMetadata(),
        didDocumentMetadata = didDocumentMetadata ?? DidDocumentMetadata();

  /// A convenience constructor for creating a [DidResolutionResult] representing
  /// an invalid DID scenario. This sets the resolution metadata error to 'invalidDid'
  /// and leaves the DID document as `null`.
  DidResolutionResult.invalidDid()
      : didResolutionMetadata = DidResolutionMetadata(error: 'invalidDid'),
        didDocument = null,
        didDocumentMetadata = DidDocumentMetadata();

  /// Converts this [DidResolutionResult] instance to a JSON map.
  ///
  /// Returns a map containing the JSON representation of the resolution metadata,
  /// the DID document (if available), and the document metadata.
  ///
  /// This can be used for serialization or transmission of the resolution result.
  Map<String, dynamic> toJson() {
    return {
      'didResolutionMetadata': didResolutionMetadata.toJson(),
      'didDocument': didDocument?.toJson(),
      'didDocumentMetadata': didDocumentMetadata.toJson(),
    };
  }

  bool hasError() {
    return didResolutionMetadata.error != null;
  }
}
