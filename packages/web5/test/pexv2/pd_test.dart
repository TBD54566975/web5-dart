import 'package:test/test.dart';
import 'package:web5/src/pexv2/pd.dart';

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
    final input =  Map<String, dynamic>.from(json['input']);
    final output =  Map<String, dynamic>.from(json['output']);

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
      final vectorsJson =
          getJsonVectors('presentation_exchange/select_credentials.json');
      final vectorsJson2 =
          getJsonVectors('presentation_exchange/select_credentials_go.json');
 
      final vectors = [...vectorsJson['vectors'], ...vectorsJson2['vectors']]
          .map((e) => SelectCredentialTestVector.fromJson(e))
          .toList();

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
