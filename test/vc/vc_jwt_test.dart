import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:web5/web5.dart';

void main() {
  group('decode', () {
    late BearerDid signerDid;
    late VerifiableCredential vc;

    setUp(() async {
      signerDid = await DidJwk.create();
      vc = VerifiableCredential.create(
        data: {'foo': 'bar'},
        issuer: 'did:ex:pfi',
        subject: 'did:ex:alice',
      );
    });

    test('returns a DecodedVcJwt with vc and jwt', () async {
      final vcJwt = await vc.sign(signerDid);

      final decodedVcJwt = DecodedVcJwt.decode(vcJwt);
      expect(decodedVcJwt.vc, isNotNull);
      expect(decodedVcJwt.jwt, isNotNull);
    });

    test('throws if vc-jwt is missing claims', () async {
      // Sign without setting claims
      final header = JwtHeader(typ: 'JWT');
      final vcJwt =
          await Jws.sign(did: signerDid, payload: Uint8List(0), header: header);

      expect(() => DecodedVcJwt.decode(vcJwt), throwsException);
    });

    test('throws if vc-jwt is missing vc claims', () async {
      signWithoutVcClaims(VerifiableCredential vc, BearerDid bearerDid) async {
        final claims = JwtClaims(
          iss: vc.issuer,
          jti: vc.id,
          sub: vc.subject,
        );

        final issuanceDateTime = DateTime.parse(vc.issuanceDate);
        claims.nbf = issuanceDateTime.millisecondsSinceEpoch ~/ 1000;

        if (vc.expirationDate != null) {
          final expirationDateTime = DateTime.parse(vc.expirationDate!);
          claims.exp = expirationDateTime.millisecondsSinceEpoch ~/ 1000;
        }

        // deliberately omit: claims.misc = <String, dynamic>{'vc': vc.toJson()};

        return await Jwt.sign(did: bearerDid, payload: claims);
      }

      final vcJwt = await signWithoutVcClaims(vc, signerDid);
      expect(() => DecodedVcJwt.decode(vcJwt), throwsException);
    });

    test('sets vc issuer to jwt iss', () async {
      signAndSetCustomIss(
        VerifiableCredential vc,
        BearerDid bearerDid,
        String iss,
      ) async {
        final claims = JwtClaims(
          iss: iss,
          jti: vc.id,
          sub: vc.subject,
        );

        final issuanceDateTime = DateTime.parse(vc.issuanceDate);
        claims.nbf = issuanceDateTime.millisecondsSinceEpoch ~/ 1000;

        if (vc.expirationDate != null) {
          final expirationDateTime = DateTime.parse(vc.expirationDate!);
          claims.exp = expirationDateTime.millisecondsSinceEpoch ~/ 1000;
        }

        claims.misc = <String, dynamic>{'vc': vc.toJson()};

        return await Jwt.sign(did: bearerDid, payload: claims);
      }

      final iss = 'did:ex:custom';
      final vcJwt = await signAndSetCustomIss(vc, signerDid, iss);
      final decodedVcJwt = DecodedVcJwt.decode(vcJwt);
      expect(decodedVcJwt.vc.issuer, equals(iss));
    });

    test('sets vc id to jwt jti', () async {
      signAndSetCustomJti(
        VerifiableCredential vc,
        BearerDid bearerDid,
        String jti,
      ) async {
        final claims = JwtClaims(
          iss: vc.issuer,
          jti: jti,
          sub: vc.subject,
        );

        final issuanceDateTime = DateTime.parse(vc.issuanceDate);
        claims.nbf = issuanceDateTime.millisecondsSinceEpoch ~/ 1000;

        if (vc.expirationDate != null) {
          final expirationDateTime = DateTime.parse(vc.expirationDate!);
          claims.exp = expirationDateTime.millisecondsSinceEpoch ~/ 1000;
        }

        claims.misc = <String, dynamic>{'vc': vc.toJson()};

        return await Jwt.sign(did: bearerDid, payload: claims);
      }

      final jti = 'custom-id';
      final vcJwt = await signAndSetCustomJti(vc, signerDid, jti);
      final decodedVcJwt = DecodedVcJwt.decode(vcJwt);
      expect(decodedVcJwt.vc.id, equals(jti));
    });

    test('sets vc subject if jwt sub', () async {
      signAndSetCustomSub(
        VerifiableCredential vc,
        BearerDid bearerDid,
        String sub,
      ) async {
        final claims = JwtClaims(
          iss: vc.issuer,
          jti: vc.id,
          sub: sub,
        );

        final issuanceDateTime = DateTime.parse(vc.issuanceDate);
        claims.nbf = issuanceDateTime.millisecondsSinceEpoch ~/ 1000;

        if (vc.expirationDate != null) {
          final expirationDateTime = DateTime.parse(vc.expirationDate!);
          claims.exp = expirationDateTime.millisecondsSinceEpoch ~/ 1000;
        }

        claims.misc = <String, dynamic>{'vc': vc.toJson()};

        return await Jwt.sign(did: bearerDid, payload: claims);
      }

      final sub = 'did:ex:custom';
      final vcJwt = await signAndSetCustomSub(vc, signerDid, sub);
      final decodedVcJwt = DecodedVcJwt.decode(vcJwt);
      expect(decodedVcJwt.vc.subject, equals(sub));
    });

    test('sets vc expirationDate to jwt exp', () async {
      signAndSetCustomExp(
        VerifiableCredential vc,
        BearerDid bearerDid,
        int exp,
      ) async {
        final claims = JwtClaims(
          iss: vc.issuer,
          jti: vc.id,
          sub: vc.subject,
        );

        final issuanceDateTime = DateTime.parse(vc.issuanceDate);
        claims.nbf = issuanceDateTime.millisecondsSinceEpoch ~/ 1000;

        claims.exp = exp;

        claims.misc = <String, dynamic>{'vc': vc.toJson()};

        return await Jwt.sign(did: bearerDid, payload: claims);
      }

      final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final nowRounded =
          DateTime.fromMillisecondsSinceEpoch(exp * 1000).toString();

      final vcJwt = await signAndSetCustomExp(vc, signerDid, exp);
      final decodedVcJwt = DecodedVcJwt.decode(vcJwt);
      expect(decodedVcJwt.vc.expirationDate, equals(nowRounded));
    });

    test('sets vc issuanceDate to vc nbf', () async {
      signAndSetCustomNbf(
        VerifiableCredential vc,
        BearerDid bearerDid,
        int nbf,
      ) async {
        final claims = JwtClaims(
          iss: vc.issuer,
          jti: vc.id,
          sub: vc.subject,
        );

        claims.nbf = nbf;

        if (vc.expirationDate != null) {
          final expirationDateTime = DateTime.parse(vc.expirationDate!);
          claims.exp = expirationDateTime.millisecondsSinceEpoch ~/ 1000;
        }
        claims.misc = <String, dynamic>{'vc': vc.toJson()};

        return await Jwt.sign(did: bearerDid, payload: claims);
      }

      final nbf = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final nowRounded =
          DateTime.fromMillisecondsSinceEpoch(nbf * 1000).toString();

      final vcJwt = await signAndSetCustomNbf(vc, signerDid, nbf);
      final decodedVcJwt = DecodedVcJwt.decode(vcJwt);
      expect(decodedVcJwt.vc.issuanceDate, equals(nowRounded));
    });
  });

  group('verify', () {
    late BearerDid signerDid;
    late VerifiableCredential vc;
    late DecodedVcJwt decodedVcJwt;

    setUp(() async {
      signerDid = await DidJwk.create();
      vc = VerifiableCredential.create(
        data: {'foo': 'bar'},
        issuer: 'did:ex:pfi',
        subject: 'did:ex:alice',
      );
      final vcJwt = await vc.sign(signerDid);
      decodedVcJwt = DecodedVcJwt.decode(vcJwt);
    });

    test('returns successfully for well-formed VcJwt', () async {
      await expectLater(decodedVcJwt.verify(), completes);
    });

    test('throws if jwt.header.typ is not "JWT"', () async {
      decodedVcJwt.jwt.header.typ = 'GARBAGE';
      expect(() async => await decodedVcJwt.verify(), throwsException);
    });

    test('throws if vc issuer is missing', () async {
      decodedVcJwt.vc.issuer = '';
      expect(() async => await decodedVcJwt.verify(), throwsException);
    });

    test('throws if vc id is missing', () async {
      decodedVcJwt.vc.id = '';
      expect(() async => await decodedVcJwt.verify(), throwsException);
    });

    test('throws if issuanceDate is in the future', () async {
      final tomorrow = DateTime.now().add(Duration(hours: 24));
      decodedVcJwt.vc.issuanceDate = tomorrow.toString();
      expect(() async => await decodedVcJwt.verify(), throwsException);
    });

    test('throws if expirationDate is in the past', () async {
      final yesterday = DateTime.now().subtract(Duration(hours: 24));
      decodedVcJwt.vc.expirationDate = yesterday.toString();
      expect(() async => await decodedVcJwt.verify(), throwsException);
    });

    test('throws if type is empty', () async {
      decodedVcJwt.vc.type = [];
      expect(() async => await decodedVcJwt.verify(), throwsException);
    });

    test('throws if type does not contain base type', () async {
      decodedVcJwt.vc.type = ['GARBAGE'];
      expect(() async => await decodedVcJwt.verify(), throwsException);
    });

    test('throws if context is empty', () async {
      decodedVcJwt.vc.context = [];
      expect(() async => await decodedVcJwt.verify(), throwsException);
    });

    test('throws if context does not contain base context', () async {
      decodedVcJwt.vc.context = ['GARBAGE'];
      expect(() async => await decodedVcJwt.verify(), throwsException);
    });

    test('throws if signature is wrong', () async {
      var vcJwt = await vc.sign(signerDid);
      final parts = vcJwt.split('.');
      vcJwt = [
        parts[0],
        parts[1],
        Base64Url.encode(List.filled(64, 0)), // malformed signature
      ].join('.');
      final decodedVcJwt = DecodedVcJwt.decode(vcJwt);

      expect(() async => await decodedVcJwt.verify(), throwsException);
    });
  });
}
