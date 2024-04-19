enum DidDhtRegisteredDidType {
  discoverable(0, 'Discoverable'),
  organization(1, 'Organization'),
  government(2, 'Government Organization'),
  corporation(3, 'Corporation'),
  localBusiness(4, 'Local Business'),
  softwarePackage(5, 'Software Package'),
  webApp(6, 'Web App'),
  financialInstitution(7, 'Financial Institution');

  final int value;
  final String description;

  const DidDhtRegisteredDidType(this.value, this.description);

  static DidDhtRegisteredDidType fromValue(int value) {
    return DidDhtRegisteredDidType.values.firstWhere(
      (type) => type.value == value,
      orElse: () =>
          throw Exception('Unknown value for DidDhtRegisteredDidType: $value'),
    );
  }

  static DidDhtRegisteredDidType fromName(String name) {
    return DidDhtRegisteredDidType.values.firstWhere(
      (type) => type.description.toLowerCase() == name.toLowerCase(),
      orElse: () =>
          throw Exception('Unknown name for DidDhtRegisteredDidType: $name'),
    );
  }
}
