import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:json_path/json_path.dart';
import 'package:web5/src/pexv2/pd.dart';

class FieldPath {
  List<String> paths;

  FieldPath({required this.paths});
}

/// This function selects the Verifiable Credentials (VCs) that satisfy the constraints specified in the Presentation Definition
Future<List<String>> selectCredentials(
  List<String> vcJwts,
  PresentationDefinition pd,
) async {
  final fieldPaths = <String, FieldPath>{};
  final fieldFilters = <String, Filter>{};

  // Extract the field paths and filters from the input descriptors
  for (var inputDescriptor in pd.inputDescriptors) {
    if (inputDescriptor.constraints.fields == null) {
      continue;
    }

    for (var field in inputDescriptor.constraints.fields!) {
      final token = generateRandomToken();
      final paths = field.path;
      if (paths != null) {
        fieldPaths[token] = FieldPath(paths: paths);
      }
      if (field.filter != null) {
        fieldFilters[token] = field.filter!;
      }
    }
  }

  final selectionCandidates = <String, dynamic>{};

  // Find vcJwts whose fields match the fieldPaths
  for (var vcJwt in vcJwts) {
    final decoded = json.decode(vcJwt); // Simulating decoding a JWT

    for (var fieldToken in fieldPaths.entries) {
      for (var path in fieldToken.value.paths) {
        final jsondata = decoded;
        final value = JsonPath(path).read(jsondata).firstOrNull;

        if (value != null) {
          selectionCandidates[vcJwt] = value;
          break;
        }
      }
    }
  }

  final matchingVcJWTs = <String>[];

  // If no field filters are specified in PD, return all the vcJwts that matched the fieldPaths
  if (fieldFilters.isEmpty) {
    return selectionCandidates.keys.toList();
  }

  // Filter further for vcJwts whose fields match the fieldFilters
  for (var entry in selectionCandidates.entries) {
    for (var filter in fieldFilters.values) {
      if (satisfiesFieldFilter(entry.value, filter)) {
        matchingVcJWTs.add(entry.key);
      }
    }
  }

  return matchingVcJWTs;
}

bool satisfiesFieldFilter(dynamic fieldValue, Filter filter) {
  // Check if the field value matches the constant if specified
  if (filter.constValue != null) {
    return fieldValue.toString() == filter.constValue;
  }

  // Type checking and pattern matching
  if (filter.type != null || filter.pattern != null) {
    switch (filter.type) {
      case 'string':
        if (filter.pattern != null) {
          return RegExp(filter.pattern!).hasMatch(fieldValue.toString());
        }
        break;
      case 'number':
        if (fieldValue is num) {
          return true;
        }
        break;
      case 'array':
        if (fieldValue is List && filter.contains != null) {
          return fieldValue
              .any((item) => satisfiesFieldFilter(item, filter.contains!));
        }
        break;
      default:
        return false;
    }
  }

  return true;
}

String generateRandomToken() {
  final rand = Random.secure();
  final bytes = Uint8List(16);
  for (int i = 0; i < 16; i++) {
    bytes[i] = rand.nextInt(256);
  }
  return hex.encode(bytes);
}
