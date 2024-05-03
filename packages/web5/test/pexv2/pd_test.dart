import 'package:test/test.dart';
import 'package:web5/src/pexv2/pd.dart';

import '../helpers/test_vector_helpers.dart';


class SelectCredentialTestVector {
  String description;

  // Input
  PresentationDefinition inputPresentationDefinition;
  List<String> inputVcJwts;

  // output
  List<String> outputSelectedCredentials;
  bool errors;

  SelectCredentialTestVector({
    required this.description,
    required this.inputPresentationDefinition,
    required this.inputVcJwts,
    required this.outputSelectedCredentials,
    this.errors = false,
  });

  factory SelectCredentialTestVector.fromJson(Map<String, dynamic> json) {
    return SelectCredentialTestVector(
      description: json['description'],
      inputPresentationDefinition: PresentationDefinition.fromJson(
        json['input']['presentationDefinition'],
      ),
      inputVcJwts: json['input']['credentialJwts'],
      outputSelectedCredentials: json['output']['selectedCredentials'],
      errors: json['errors'],
    );
  }
}

void main() {
  group('select credentials', () {
    group('vectors', () {
      late List<SelectCredentialTestVector> vectors;

      setUpAll(() {
        final vectorsJson = getJsonVectors('presentation_exchange/select_credentials.json');
        vectors = (vectorsJson['vectors'] as List<Map<String, dynamic>>)
            .map(SelectCredentialTestVector.fromJson)
            .toList();
      });

      for (final vector in vectors) {
        test(vector.description, () async {
          try {
            final matchingVcJwts = vector.inputPresentationDefinition
                .selectCredentials(vector.inputVcJwts);

            if (vector.errors == true) {
              fail('Expected an error but none was thrown');
            }

            expect(
              Set.from(matchingVcJwts),
              Set.from(vector.outputSelectedCredentials),
            );
          } catch (e) {
            if (vector.errors == false) {
              fail('Expected no error but got: $e');
            }
          }
        });
      }
    });
  });
}
