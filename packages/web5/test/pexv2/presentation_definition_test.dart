import 'package:test/test.dart';
import 'package:web5/src/pexv2/presentation_definition.dart';

import '../helpers/test_vector_helpers.dart';

class SelectCredentialTestVector {
  String description;
  PresentationDefinition inputPresentationDefinition;
  List<String> inputVcJwts;
  List<String> outputSelectedCredentials;
  bool? errors;

  SelectCredentialTestVector({
    required this.description,
    required this.inputPresentationDefinition,
    required this.inputVcJwts,
    required this.outputSelectedCredentials,
  });

  factory SelectCredentialTestVector.fromJson(Map<String, dynamic> json) {
    final input = Map<String, dynamic>.from(json['input']);
    final output = Map<String, dynamic>.from(json['output']);

    return SelectCredentialTestVector(
      description: json['description'],
      inputPresentationDefinition: PresentationDefinition.fromJson(
        Map<String, dynamic>.from(input['presentationDefinition']),
      ),
      inputVcJwts: List<String>.from(input['credentialJwts']),
      outputSelectedCredentials:
          List<String>.from(output['selectedCredentials']),
    );
  }
}

void main() {
  group('select credentials', () {
    group('vectors', () {
      late List<SelectCredentialTestVector> vectors;
      setUp(() {
        final vectorsJson =
            getJsonVectors('presentation_exchange/select_credentials.json');
        final vectorsDynamic = vectorsJson['vectors'] as List<dynamic>;

        vectors = vectorsDynamic
            .map((e) => SelectCredentialTestVector.fromJson(e))
            .toList();
      });

      test('web5 test vectors', () async {
        for (final vector in vectors) {
          late List<String> matchingVcJwts;

          try {
            matchingVcJwts = vector.inputPresentationDefinition
                .selectCredentials(vector.inputVcJwts);
          } catch (e) {
            if (vector.errors != true) {
              fail(
                'Expected no error for vector (${vector.description}) but got: $e',
              );
            }
            return;
          }

          if (vector.errors == true) {
            fail(
              'Expected an error for vector (${vector.description}) but none was thrown ',
            );
          }

          expect(
            Set.from(matchingVcJwts),
            Set.from(vector.outputSelectedCredentials),
            reason: 'Test vector (${vector.description}) has mismatched output',
          );
        }
      });
    });
  });
}
