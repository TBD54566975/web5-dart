enum DidDhtRegisteredDidType {
  /// Type 0 is reserved for DIDs that do not wish to associate themselves
  /// with a specific type but wish to make themselves discoverable.
  discoverable,

  /// Organization: https://schema.org/Organization
  organization,

  /// Government Organization: https://schema.org/GovernmentOrganization
  government,

  /// Corporation: https://schema.org/Corporation
  corporation,

  /// Local Business: https://schema.org/LocalBusiness
  localBusiness,

  /// Software Package: https://schema.org/SoftwareSourceCode
  softwarePackage,

  /// Web App: https://schema.org/WebApplication
  webApp,

  /// Financial Institution: https://schema.org/FinancialService
  financialInstitution,
}

extension IntegerValue on DidDhtRegisteredDidType {
  int get value {
    switch (this) {
      case DidDhtRegisteredDidType.discoverable:
        return 0;
      case DidDhtRegisteredDidType.organization:
        return 1;
      case DidDhtRegisteredDidType.government:
        return 2;
      case DidDhtRegisteredDidType.corporation:
        return 3;
      case DidDhtRegisteredDidType.localBusiness:
        return 4;
      case DidDhtRegisteredDidType.softwarePackage:
        return 5;
      case DidDhtRegisteredDidType.webApp:
        return 6;
      case DidDhtRegisteredDidType.financialInstitution:
        return 7;
      default:
        throw 'Unable to get value for DidDhtRegisteredDidType $this';
    }
  }
}
