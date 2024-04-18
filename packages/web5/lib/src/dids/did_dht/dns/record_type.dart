// ignore_for_file: constant_identifier_names

/// Enum representing DNS record types.
enum RecordType {
  /// Address record, maps a domain name to an IPv4 address.
  A(1, 'A'),

  /// Obsolete record type.
  NULL(10, 'NULL'),

  /// IPv6 address record, maps a domain name to an IPv6 address.
  AAAA(28, 'AAAA'),

  /// AFS database record.
  AFSDB(18, 'AFSDB'),

  /// Address prefix list record.
  APL(42, 'APL'),

  /// Certification Authority Authorization record.
  CAA(257, 'CAA'),

  /// Child DNSKEY record.
  CDNSKEY(60, 'CDNSKEY'),

  /// Child DS record.
  CDS(59, 'CDS'),

  /// Certificate record.
  CERT(37, 'CERT'),

  /// Canonical name record, used for domain aliases.
  CNAME(5, 'CNAME'),

  /// DHCP identifier record.
  DHCID(49, 'DHCID'),

  /// DNSSEC Lookaside Validation record.
  DLV(32769, 'DLV'),

  /// Delegation name record.
  DNAME(39, 'DNAME'),

  /// DNS key record.
  DNSKEY(48, 'DNSKEY'),

  /// Delegation signer record.
  DS(43, 'DS'),

  /// Host identity protocol record.
  HIP(55, 'HIP'),

  /// Host information record.
  HINFO(13, 'HINFO'),

  /// IPsec key record.
  IPSECKEY(45, 'IPSECKEY'),

  /// Key record, used for DNSSEC.
  KEY(25, 'KEY'),

  /// Key exchanger record.
  KX(36, 'KX'),

  /// Location record.
  LOC(29, 'LOC'),

  /// Mail exchange record, specifies mail servers for a domain.
  MX(15, 'MX'),

  /// Naming authority pointer record.
  NAPTR(35, 'NAPTR'),

  /// Name server record, specifies authoritative name servers for a domain.
  NS(2, 'NS'),

  /// Next-secure record, part of DNSSEC.
  NSEC(47, 'NSEC'),

  /// Next-secure record version 3.
  NSEC3(50, 'NSEC3'),

  /// NSEC3 parameters record.
  NSEC3PARAM(51, 'NSEC3PARAM'),

  /// Pointer record, maps an IP address to a host name for reverse DNS lookups.
  PTR(12, 'PTR'),

  /// DNSSEC signature record.
  RRSIG(46, 'RRSIG'),

  /// Responsible person record.
  RP(17, 'RP'),

  /// Signature record, used for DNSSEC.
  SIG(24, 'SIG'),

  /// Start of authority record, contains administrative information about a DNS zone.
  SOA(6, 'SOA'),

  /// Sender policy framework record, used for email validation.
  SPF(99, 'SPF'),

  /// Service locator record, used for service discovery.
  SRV(33, 'SRV'),

  /// SSH fingerprint record.
  SSHFP(44, 'SSHFP'),

  /// Trust anchor record.
  TA(32768, 'TA'),

  /// Transaction key record.
  TKEY(249, 'TKEY'),

  /// Transport layer security association record.
  TLSA(52, 'TLSA'),

  /// Transaction signature record, used for DNS updates.
  TSIG(250, 'TSIG'),

  /// Text record, can contain arbitrary text data.
  TXT(16, 'TXT'),

  /// Authoritative zone transfer record.
  AXFR(252, 'AXFR'),

  /// Incremental zone transfer record.
  IXFR(251, 'IXFR'),

  /// Option record, used for extended DNS (EDNS).
  OPT(41, 'OPT'),

  /// "Any" record type, used in DNS queries to request all available record types.
  ANY(255, 'ANY'),

  /// Represents an unknown or unsupported DNS record type.
  UNKNOWN(0, 'UNKNOWN');

  final int value;
  final String name;
  final int numBytes = 2;

  const RecordType(this.value, this.name);

  static RecordType fromValue(int value) {
    return RecordType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RecordType.UNKNOWN,
    );
  }

  static RecordType fromName(String name) {
    return RecordType.values.firstWhere(
      (type) => type.name.toUpperCase() == name.toUpperCase(),
      orElse: () => RecordType.UNKNOWN,
    );
  }
}
