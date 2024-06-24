// ignore_for_file: constant_identifier_names

enum RecordClass {
  IN(1, 'IN'),
  CS(2, 'CS'),
  CH(3, 'CH'),
  HS(4, 'HS'),
  ANY(255, 'ANY'),
  UNKNOWN(0, 'UNKNOWN'); // Default for unknown classes

  final int value;
  final String name;
  final int numBytes = 2;

  const RecordClass(this.value, this.name);

  static RecordClass fromValue(int value) {
    return RecordClass.values.firstWhere(
      (kls) => kls.value == value,
      orElse: () => RecordClass.UNKNOWN, // Default or a suitable fallback
    );
  }

  static RecordClass fromName(String name) {
    return RecordClass.values.firstWhere(
      (kls) => kls.name.toUpperCase() == name.toUpperCase(),
      orElse: () => RecordClass.UNKNOWN, // Default or a suitable fallback
    );
  }
}
