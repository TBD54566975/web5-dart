import 'package:test/test.dart';
import 'package:web5/web5.dart';

void main() {
  group('create', () {
    test('uses default values for type, context, id, and issuanceDate',
        () async {
      final data = {'foo': 'bar'};
      final issuer = 'did:ex:pfi';
      final subject = 'did:ex:alice';
      final vc = VerifiableCredential.create(
        data: data,
        issuer: issuer,
        subject: subject,
      );

      expect(vc.data, equals(data));
      expect(vc.subject, equals(subject));
      expect(vc.issuer, equals(issuer));
      expect(vc.type, equals(['VerifiableCredential']));
      expect(vc.context, equals(['https://www.w3.org/2018/credentials/v1']));
      expect(vc.issuanceDate, isNotNull);
      expect(vc.id, startsWith('urn:vc:uuid:'));
      expect(vc.expirationDate, isNull);
      expect(vc.credentialSchema, equals([]));
    });

    test('accepts values passed in options', () async {
      final data = {'foo': 'bar'};
      final issuer = 'did:ex:pfi';
      final subject = 'did:ex:alice';
      final context = ['SomeContext'];
      final type = ['SomeType'];
      final id = 'urn:vc:uuid:1234';
      final issuanceDate = DateTime.now().subtract(Duration(hours: 24));
      final expirationDate = DateTime.now().subtract(Duration(hours: 12));
      final credentialSchema = [
        CredentialSchema(id: 'id', type: 'CredentialType'),
      ];

      final vc = VerifiableCredential.create(
        data: data,
        issuer: issuer,
        subject: subject,
        context: context,
        type: type,
        id: id,
        issuanceDate: issuanceDate,
        expirationDate: expirationDate,
        credentialSchema: credentialSchema,
      );

      expect(vc.data, equals(data));
      expect(vc.subject, equals(subject));
      expect(vc.issuer, equals(issuer));
      expect(vc.type, equals(type));
      expect(vc.context, equals(context));
      expect(DateTime.parse(vc.issuanceDate), equals(issuanceDate));
      expect(vc.id, equals(id));
      expect(DateTime.parse(vc.expirationDate!), equals(expirationDate));
      expect(vc.credentialSchema, equals(credentialSchema));
    });
  });

  group('sign', () {
    test('returns a JWT signed by the BearerDid', () async {
      final did = await DidJwk.create();

      final data = {'foo': 'bar'};
      final issuer = did.uri;
      final subject = 'did:ex:alice';
      final vc = VerifiableCredential.create(
        data: data,
        issuer: issuer,
        subject: subject,
      );

      final vcJwt = await vc.sign(did);
      await expectLater(Jwt.decode(vcJwt).verify(), completes);
    });
  });
}
