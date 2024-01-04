// ignore_for_file: constant_identifier_names

enum DnsRCode {
  NOERROR(0, 'NOERROR'),
  FORMERR(1, 'FORMERR'),
  SERVFAIL(2, 'SERVFAIL'),
  NXDOMAIN(3, 'NXDOMAIN'),
  NOTIMP(4, 'NOTIMP'),
  REFUSED(5, 'REFUSED'),
  YXDOMAIN(6, 'YXDOMAIN'),
  YXRRSET(7, 'YXRRSET'),
  NXRRSET(8, 'NXRRSET'),
  NOTAUTH(9, 'NOTAUTH'),
  NOTZONE(10, 'NOTZONE'),
  RCODE_11(11, 'RCODE_11'),
  RCODE_12(12, 'RCODE_12'),
  RCODE_13(13, 'RCODE_13'),
  RCODE_14(14, 'RCODE_14'),
  RCODE_15(15, 'RCODE_15');

  final int value;
  final String name;

  const DnsRCode(this.value, this.name);

  static DnsRCode fromValue(int value) {
    return DnsRCode.values.firstWhere(
      (rc) => rc.value == value,
      orElse: () => DnsRCode.NOERROR, // Default or a suitable fallback
    );
  }

  static DnsRCode fromName(String name) {
    return DnsRCode.values.firstWhere(
      (rc) => rc.name.toUpperCase() == name.toUpperCase(),
      orElse: () => DnsRCode.NOERROR, // Default or a suitable fallback
    );
  }
}
