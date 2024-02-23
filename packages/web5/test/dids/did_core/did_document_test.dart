import 'dart:convert';

import 'package:test/test.dart';
import 'package:web5/src/crypto.dart';
import 'package:web5/src/dids/did_core.dart';

void main() {
  group('DidDocument', () {
    group('getVerificationMethod', () {
      test('should return null if no verificationMethod exists', () {
        // Arrange
        final didDocument = DidDocument(id: 'did:example:123');
        // Act
        final result = didDocument.getVerificationMethod();
        // Assert
        expect(result, isNull);
      });

      test('should return first verificationMethod if no id is provided', () {
        // Arrange
        final didDocument = DidDocument(
          id: 'did:example:123',
          verificationMethod: [
            DidVerificationMethod(
              id: 'did:example:123#key-1',
              type: 'JsonWebKey2020',
              controller: 'did:example:123',
              publicKeyJwk: Jwk(
                kty: 'OKP',
                crv: 'Ed25519',
                x: '123',
              ),
            ),
            DidVerificationMethod(
              id: 'did:example:123#key-2',
              type: 'JsonWebKey2020',
              controller: 'did:example:123',
              publicKeyJwk: Jwk(
                kty: 'OKP',
                crv: 'Ed25519',
                x: '456',
              ),
            ),
          ],
        );
        // Act
        final result = didDocument.getVerificationMethod();
        // Assert
        expect(result, isA<DidVerificationMethod>());
        expect(result!.id, 'did:example:123#key-1');
      });

      test('should return verificationMethod by id', () {
        // Arrange
        final didDocument = DidDocument(
          id: 'did:example:123',
          verificationMethod: [
            DidVerificationMethod(
              id: 'did:example:123#key-1',
              type: 'JsonWebKey2020',
              controller: 'did:example:123',
              publicKeyJwk: Jwk(
                kty: 'OKP',
                crv: 'Ed25519',
                x: '123',
              ),
            ),
            DidVerificationMethod(
              id: 'did:example:123#key-2',
              type: 'JsonWebKey2020',
              controller: 'did:example:123',
              publicKeyJwk: Jwk(
                kty: 'OKP',
                crv: 'Ed25519',
                x: '456',
              ),
            ),
          ],
        );
        // Act
        final result =
            didDocument.getVerificationMethod(id: 'did:example:123#key-2');
        // Assert
        expect(result, isA<DidVerificationMethod>());
        expect(result!.id, 'did:example:123#key-2');
      });
    });

    test('should return null if no vm exists with provided purpose', () {
      // Arrange
      final didDocument = DidDocument(id: 'did:example:123');
      // Act
      final result = didDocument.getVerificationMethod(
        purpose: VerificationPurpose.authentication,
      );
      // Assert
      expect(result, isNull);
    });

    test('should return vm with provided purpose', () {
      final didDocument = DidDocument(id: 'did:example:123');
      final vm = DidVerificationMethod(
        id: 'did:example:123#key-1',
        type: 'JsonWebKey2020',
        controller: 'did:example:123',
        publicKeyJwk: Jwk(
          kty: 'OKP',
          crv: 'Ed25519',
          x: '123',
        ),
      );

      didDocument.addVerificationMethod(
        vm,
        purpose: VerificationPurpose.authentication,
      );

      final result = didDocument.getVerificationMethod(
        purpose: VerificationPurpose.authentication,
      );

      expect(result, isA<DidVerificationMethod>());
      expect(result!.id, 'did:example:123#key-1');
    });
  });
}
