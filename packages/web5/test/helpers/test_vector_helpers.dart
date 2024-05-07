import 'dart:convert';
import 'dart:io';

final thisDir = Directory.current.path;
final vectorDir = '$thisDir/../../web5-spec/test-vectors/';

Map<String, dynamic> getJsonVectors(String vectorSubPath) {
  final vectorPath = '$vectorDir$vectorSubPath';
  final file = File(vectorPath);

  try {
    final contents = file.readAsStringSync();
    return json.decode(contents);
  } catch (e) {
    throw Exception('Failed to load verify test vectors: $e');
  }
}
