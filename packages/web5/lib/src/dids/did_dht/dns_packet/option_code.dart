// ignore_for_file: constant_identifier_names

enum DnsOptionCode {
  LLQ(1, 'LLQ'),
  UL(2, 'UL'),
  NSID(3, 'NSID'),
  DAU(5, 'DAU'),
  DHU(6, 'DHU'),
  N3U(7, 'N3U'),
  CLIENT_SUBNET(8, 'CLIENT_SUBNET'),
  EXPIRE(9, 'EXPIRE'),
  COOKIE(10, 'COOKIE'),
  TCP_KEEPALIVE(11, 'TCP_KEEPALIVE'),
  PADDING(12, 'PADDING'),
  CHAIN(13, 'CHAIN'),
  KEY_TAG(14, 'KEY_TAG'),
  DEVICEID(26946, 'DEVICEID'),
  UNKNOWN(-1, 'UNKNOWN'); // Default for unknown or undefined types

  final int value;
  final String name;

  const DnsOptionCode(this.value, this.name);

  static DnsOptionCode fromValue(int value) {
    return DnsOptionCode.values.firstWhere((opt) => opt.value == value,
        orElse: () => DnsOptionCode.UNKNOWN, // Default or a suitable fallback
        );
  }

  static DnsOptionCode fromName(String name) {
    if (name.startsWith('OPTION_')) {
      final value = int.tryParse(name.substring(7)) ?? -1;
      return fromValue(value);
    }
    return DnsOptionCode.values.firstWhere(
        (opt) => opt.name.toUpperCase() == name.toUpperCase(),
        orElse: () => DnsOptionCode.UNKNOWN, // Default or a suitable fallback
        );
  }
}
