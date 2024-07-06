import 'package:json_path/json_path.dart';
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

      test('failing pd test', () async {
        final vcs = [
          'eyJhbGciOiJFZERTQSIsImtpZCI6ImRpZDp3ZWI6bG9jYWxob3N0JTNBODg5MSMwIiwidHlwIjoiSldUIn0.eyJleHAiOjE3NTE3NDg1MzIsImlzcyI6ImRpZDp3ZWI6bG9jYWxob3N0JTNBODg5MSIsImp0aSI6ImUyN2M2MzQ0LTUzNjItNDEwOC1hN2RmLTg4MDNlMWU4OWI0NyIsIm5iZiI6MTcyMDIxMjUzMiwic3ViIjoiZGlkOmRodDpnb3p0NnNwaThqb3lqZ2d5cjl5NHp6ZXh6a2FiaGF6aWV6ZDVvYXlwcXh1NzhjcWo4cnN5IiwidmMiOnsiQGNvbnRleHQiOlsiaHR0cHM6Ly93d3cudzMub3JnLzIwMTgvY3JlZGVudGlhbHMvdjEiXSwidHlwZSI6WyJWZXJpZmlhYmxlQ3JlZGVudGlhbCJdLCJpc3N1ZXIiOiJkaWQ6d2ViOmxvY2FsaG9zdCUzQTg4OTEiLCJjcmVkZW50aWFsU3ViamVjdCI6eyJpZCI6ImRpZDpkaHQ6Z296dDZzcGk4am95amdneXI5eTR6emV4emthYmhhemllemQ1b2F5cHF4dTc4Y3FqOHJzeSIsImNvdW50cnlPZlJlc2lkZW5jZSI6IlVTIiwidGllciI6IkdvbGQifSwiaWQiOiJlMjdjNjM0NC01MzYyLTQxMDgtYTdkZi04ODAzZTFlODliNDciLCJpc3N1YW5jZURhdGUiOiIyMDI0LTA3LTA1VDIwOjQ4OjUyWiIsImV4cGlyYXRpb25EYXRlIjoiMjAyNS0wNy0wNVQyMDo0ODo1MloiLCJjcmVkZW50aWFsU2NoZW1hIjpbeyJ0eXBlIjoiSnNvblNjaGVtYSIsImlkIjoiaHR0cDovLzE5Mi4xNjguMS43Nzo1MTczL3NjaGVtYS9rY2MuanNvbiJ9XX19.OpDh-bkpBHDdiSCzdRUOu5c-lxi7NSEOLNXP-v4hqXRh6NiTfcbsoNTivY36SWW4NWTqSBZZe4xN8Lkxf0CPCg',
        ];

        final pd = PresentationDefinition.fromJson({
          'id': '',
          'input_descriptors': [
            {
              'id': '1',
              'constraints': {
                'fields': [
                  {
                    'path': [r'$.vc.credentialSchema[*].id'],
                    'filter': {
                      'type': 'array',
                      'contains': {
                        'type': 'string',
                        'const': 'http://192.168.1.77:5173/schema/kcc.json',
                      },
                    },
                  },
                  {
                    'path': [r'$.vc.issuer'],
                    'filter': {
                      'type': 'string',
                      'const': 'did:web:localhost%3A8891',
                    },
                  }
                ],
              },
            }
          ],
        });

        expect(pd.selectCredentials(vcs), isNotEmpty);
      });

      test('shite jsonpath', () {
        final brobject = {
          'a': [
            {'id': 'a_weehee'},
            {'id': 'a_weehee2'},
          ],
          'b': [
            {'id': 'b_weehee'},
            {'id': 'b_weehee2'},
          ],
          'c': 'c_weehee',
          'd': {
            'id': 'd_weehee',
          },
        };

        final path = r'$.d[*].id';
        final idk = JsonPath(r'$.a[*].id').readValues(brobject);
        dynamic value;
        if (path.contains('[*]')) {
          value = idk.toList();
        } else {
          value = idk;
        }

        print(value);
      });
    });
  });
}
