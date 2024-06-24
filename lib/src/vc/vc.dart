import 'package:uuid/uuid.dart';
import 'package:web5/web5.dart';

class CredentialSchema {
  String id;
  String? type;

  CredentialSchema({
    required this.id,
    this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
    };
  }
}

class VerifiableCredential {
  // https://www.w3.org/TR/vc-data-model/#contexts
  static final baseContext = 'https://www.w3.org/2018/credentials/v1';
  // https://www.w3.org/TR/vc-data-model/#dfn-type
  static final baseType = 'VerifiableCredential';

  // https://www.w3.org/TR/vc-data-model/#contexts
  List<String> context;
  // https://www.w3.org/TR/vc-data-model/#dfn-type
  List<String> type;
  // https://www.w3.org/TR/vc-data-model/#issuer
  String issuer;
  // https://www.w3.org/TR/vc-data-model/#credential-subject
  String subject;
  Map<String, dynamic> data;
  // https://www.w3.org/TR/vc-data-model/#identifiers
  String id;
  // https://www.w3.org/TR/vc-data-model/#issuance-date
  String issuanceDate;
  // https://www.w3.org/TR/vc-data-model/#expiration
  String? expirationDate;
  // https://www.w3.org/TR/vc-data-model-2.0/#data-schemas
  List<CredentialSchema>? credentialSchema;

  VerifiableCredential._({
    required this.context,
    required this.type,
    required this.issuer,
    required this.subject,
    required this.data,
    required this.issuanceDate,
    required this.id,
    this.expirationDate,
    this.credentialSchema = const [],
  });

  static VerifiableCredential create({
    required String issuer,
    required String subject,
    required Map<String, dynamic> data,
    List<String>? context,
    List<String>? type,
    String? id,
    DateTime? issuanceDate,
    DateTime? expirationDate,
    List<CredentialSchema> credentialSchema = const [],
  }) {
    final uuid = Uuid();

    context = context ?? [baseContext];
    type = type ?? [baseType];
    id = id ?? 'urn:vc:uuid:${uuid.v4()}';
    issuanceDate = issuanceDate ?? DateTime.now();

    return VerifiableCredential._(
      context: context,
      type: type,
      issuer: issuer,
      subject: subject,
      data: data,
      id: id,
      issuanceDate: issuanceDate.toString(),
      expirationDate: expirationDate?.toString(),
      credentialSchema: credentialSchema,
    );
  }

  Future<String> sign(
    BearerDid bearerDid,
  ) async {
    final claims = JwtClaims(
      iss: issuer,
      jti: id,
      sub: subject,
    );

    final issuanceDateTime = DateTime.parse(issuanceDate);
    claims.nbf = issuanceDateTime.millisecondsSinceEpoch ~/ 1000;

    if (expirationDate != null) {
      final expirationDateTime = DateTime.parse(expirationDate!);
      claims.exp = expirationDateTime.millisecondsSinceEpoch ~/ 1000;
    }

    claims.misc = {'vc': toJson()};

    return await Jwt.sign(did: bearerDid, payload: claims);
  }

  factory VerifiableCredential.fromJson(Map<String, dynamic> json) {
    final credentialSubject = json['credentialSubject'] as Map<String, dynamic>;
    final subject = credentialSubject.remove('id');
    var credentialSchema = null as List<CredentialSchema>?;
    if (json['credentialSchema'] != null) {
      credentialSchema = (json['credentialSchema'] as List<dynamic>)
          .map((e) => CredentialSchema(id: e['id'], type: e['type']))
          .toList();
    }
    final context = (json['@context'] as List<dynamic>).cast<String>();
    final type = (json['type'] as List<dynamic>).cast<String>();

    return VerifiableCredential._(
      issuer: json['issuer'],
      subject: subject,
      data: credentialSubject,
      id: json['id'],
      context: context,
      type: type,
      issuanceDate: json['issuanceDate'],
      expirationDate: json['expirationDate'],
      credentialSchema: credentialSchema,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '@context': context,
      'type': type,
      'issuer': issuer,
      'credentialSubject': {
        'id': subject,
        ...data,
      },
      'id': id,
      'issuanceDate': issuanceDate,
      if (expirationDate != null) 'expirationDate': expirationDate,
      if (credentialSchema != null)
        'credentialSchema': credentialSchema!
            .map(
              (e) => e.toJson(),
            )
            .toList(),
    };
  }
}
