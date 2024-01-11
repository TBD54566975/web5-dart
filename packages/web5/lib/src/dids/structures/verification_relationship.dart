/// A verification relationship expresses the relationship between the DID
/// subject and a verification method. Different verification relationships
/// enable the associated verification methods to be used for different purposes.
///  It is up to a verifier to ascertain the validity of a verification attempt
/// by checking that the verification method used is contained in the
/// appropriate verification relationship property of the DID Document.
///
/// [Specification Reference](https://www.w3.org/TR/did-core/#verification-relationships)
enum VerificationRelationship {
  /// The authentication verification relationship is used to specify how the
  /// DID subject is expected to be authenticated, for purposes such as logging
  /// into a website or engaging in any sort of challenge-response protocol.
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#authentication)
  authentication,

  /// The assertionMethod verification relationship is used to specify how the
  /// DID subject is expected to express claims, such as for the purposes of
  /// issuing a Verifiable Credential.
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#assertion)
  assertionMethod,

  /// The capabilityInvocation verification relationship is used to specify a
  /// verification method that might be used by the DID subject to invoke a
  /// cryptographic capability, such as the authorization to update the DID
  /// Document.
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#capability-invocation)
  capabilityInvocation,

  /// The capabilityDelegation verification relationship is used to specify a
  /// verification method that might be used by the DID subject to delegate
  /// a cryptographic capability, such as delegating the authority to update
  /// the DID Document to another entity.
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#capability-delegation)
  capabilityDelegation,

  /// The keyAgreement verification relationship is used to specify a
  /// verification method that might be used by the DID subject to perform
  /// cryptographic key agreement, such as when establishing secure communication
  /// channels.
  ///
  /// [Specification Reference](https://www.w3.org/TR/did-core/#key-agreement)
  keyAgreement
}
