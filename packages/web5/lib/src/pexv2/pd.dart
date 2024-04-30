/// PresentationDefinition represents a DIF Presentation Definition defined [here].
/// Presentation Definitions are objects that articulate what proofs a Verifier requires.
///
/// [here]: https://identity.foundation/presentation-exchange/#presentation-definition
class PresentationDefinition {
  String id;
  String? name;
  String? purpose;
  List<InputDescriptor> inputDescriptors;

  PresentationDefinition({
    required this.id,
    this.name,
    this.purpose,
    required this.inputDescriptors,
  });

  factory PresentationDefinition.fromJson(Map<String, dynamic> json) =>
      PresentationDefinition(
        id: json['id'],
        name: json['name'],
        purpose: json['purpose'],
        inputDescriptors: List<InputDescriptor>.from(
          json['input_descriptors'].map((x) => InputDescriptor.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'purpose': purpose,
        'input_descriptors':
            List<dynamic>.from(inputDescriptors.map((x) => x.toJson())),
      };
}

/// InputDescriptor represents a DIF Input Descriptor defined [here].
/// Input Descriptors are used to describe the information a Verifier requires of a Holder.
///
/// [here]: https://identity.foundation/presentation-exchange/#input-descriptor
class InputDescriptor {
  String id;
  String? name;
  String? purpose;
  Constraints constraints;

  InputDescriptor({
    required this.id,
    this.name,
    this.purpose,
    required this.constraints,
  });

  factory InputDescriptor.fromJson(Map<String, dynamic> json) =>
      InputDescriptor(
        id: json['id'],
        name: json['name'],
        purpose: json['purpose'],
        constraints: Constraints.fromJson(json['constraints']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'purpose': purpose,
        'constraints': constraints.toJson(),
      };
}

/// Constraints contains the requirements for a given Input Descriptor.
class Constraints {
  List<Field>? fields;

  Constraints({this.fields});

  factory Constraints.fromJson(Map<String, dynamic> json) => Constraints(
        fields: json['fields'] == null
            ? null
            : List<Field>.from(json['fields'].map((x) => Field.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        'fields': fields == null
            ? null
            : List<dynamic>.from(fields!.map((x) => x.toJson())),
      };
}

/// Field contains the requirements for a given field within a proof.
class Field {
  String? id;
  String? name;
  List<String>? path;
  String? purpose;
  Filter? filter;
  bool? optional;
  Optionality? predicate;

  Field({
    this.id,
    this.name,
    this.path,
    this.purpose,
    this.filter,
    this.optional,
    this.predicate,
  });

  factory Field.fromJson(Map<String, dynamic> json) => Field(
        id: json['id'],
        name: json['name'],
        path: json['path'] == null ? null : List<String>.from(json['path']),
        purpose: json['purpose'],
        filter: json['filter'] == null ? null : Filter.fromJson(json['filter']),
        optional: json['optional'],
        predicate: json['predicate'] == null
            ? null
            : optionalityValues.map[json['predicate']],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'purpose': purpose,
        'filter': filter?.toJson(),
        'optional': optional,
        'predicate':
            predicate == null ? null : optionalityValues.reverse[predicate],
      };
}

enum Optionality { required, preferred }

final optionalityValues = EnumValues({
  'preferred': Optionality.preferred,
  'required': Optionality.required,
});

/// Filter is a JSON Schema that is applied against the value of a field.
class Filter {
  String? type;
  String? pattern;
  String? constValue;
  Filter? contains;

  Filter({
    this.type,
    this.pattern,
    this.constValue,
    this.contains,
  });

  factory Filter.fromJson(Map<String, dynamic> json) => Filter(
        type: json['type'],
        pattern: json['pattern'],
        constValue: json['const'],
        contains:
            json['contains'] == null ? null : Filter.fromJson(json['contains']),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'pattern': pattern,
        'const': constValue,
        'contains': contains?.toJson(),
      };
}

/// Helper class for handling enums in JSON.
// TODO might not need this
class EnumValues<T> {
  Map<String, T> map;
  Map<T, String> reverseMap;

  EnumValues(this.map) : reverseMap = map.map((k, v) => MapEntry(v, k));

  Map<T, String> get reverse => reverseMap;
}
