// ignore_for_file: constant_identifier_names

enum DnsClass {
  IN(1, 'IN'),
  CS(2, 'CS'),
  CH(3, 'CH'),
  HS(4, 'HS'),
  ANY(255, 'ANY'),
  UNKNOWN(0, 'UNKNOWN'); // Default for unknown classes

  final int value;
  final String name;
  final int numBytes = 2;

  const DnsClass(this.value, this.name);

  static DnsClass fromValue(int value) {
    return DnsClass.values.firstWhere(
      (kls) => kls.value == value,
      orElse: () => DnsClass.UNKNOWN, // Default or a suitable fallback
    );
  }

  static DnsClass fromName(String name) {
    return DnsClass.values.firstWhere(
      (kls) => kls.name.toUpperCase() == name.toUpperCase(),
      orElse: () => DnsClass.UNKNOWN, // Default or a suitable fallback
    );
  }
}
