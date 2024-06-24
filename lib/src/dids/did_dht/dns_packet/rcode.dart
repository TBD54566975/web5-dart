// ignore_for_file: constant_identifier_names

enum RCode {
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

  const RCode(this.value, this.name);

  static RCode fromValue(int value) {
    return RCode.values.firstWhere(
      (rc) => rc.value == value,
      orElse: () => RCode.NOERROR, // Default or a suitable fallback
    );
  }

  static RCode fromName(String name) {
    return RCode.values.firstWhere(
      (rc) => rc.name.toUpperCase() == name.toUpperCase(),
      orElse: () => RCode.NOERROR, // Default or a suitable fallback
    );
  }
}
