// ignore_for_file: constant_identifier_names

enum DnsOpCode {
  QUERY(0, 'QUERY'),
  IQUERY(1, 'IQUERY'),
  STATUS(2, 'STATUS'),
  OPCODE_3(3, 'OPCODE_3'),
  NOTIFY(4, 'NOTIFY'),
  UPDATE(5, 'UPDATE'),
  OPCODE_6(6, 'OPCODE_6'),
  OPCODE_7(7, 'OPCODE_7'),
  OPCODE_8(8, 'OPCODE_8'),
  OPCODE_9(9, 'OPCODE_9'),
  OPCODE_10(10, 'OPCODE_10'),
  OPCODE_11(11, 'OPCODE_11'),
  OPCODE_12(12, 'OPCODE_12'),
  OPCODE_13(13, 'OPCODE_13'),
  OPCODE_14(14, 'OPCODE_14'),
  OPCODE_15(15, 'OPCODE_15');

  final int value;
  final String name;

  const DnsOpCode(this.value, this.name);

  static DnsOpCode fromValue(int value) {
    return DnsOpCode.values.firstWhere(
      (op) => op.value == value,
      orElse: () => DnsOpCode.QUERY, // Default or a suitable fallback
    );
  }

  static DnsOpCode fromName(String name) {
    return DnsOpCode.values.firstWhere(
      (op) => op.name.toUpperCase() == name.toUpperCase(),
      orElse: () => DnsOpCode.QUERY, // Default or a suitable fallback
    );
  }
}
