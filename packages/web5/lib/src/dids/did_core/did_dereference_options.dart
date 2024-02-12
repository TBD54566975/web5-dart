import 'dart:convert';

class DidDereferenceOptions {
  String? accept;
  Map<String, dynamic> additionalProperties;

  DidDereferenceOptions({this.accept, required this.additionalProperties});

  factory DidDereferenceOptions.fromJson(Map<String, dynamic> json) {
    return DidDereferenceOptions(
      accept: json['accept'],
      additionalProperties: json..remove('accept'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accept': accept,
      ...additionalProperties,
    };
  }

  @override
  String toString() => json.encode(toJson());
}
