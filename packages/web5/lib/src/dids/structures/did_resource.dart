/// DidResource is an abstraction that is implemented by concrete
/// resources present in DID Documents such as [Service]() and
/// [VerificationMethod](). This abstraction is necessary in order to implement
/// functionality like [DID Dereferencing] which can return either a service
/// a verification method or an entire did document
abstract class DidResource {
  String get id;
  Map<String, dynamic> toJson();
}
