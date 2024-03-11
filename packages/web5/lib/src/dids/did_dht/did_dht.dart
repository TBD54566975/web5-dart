import 'dart:io';
import 'dart:typed_data';

import 'package:web5/src/crypto.dart';
import 'package:web5/src/dids/bearer_did.dart';
import 'package:web5/src/dids/did.dart';
import 'package:web5/src/dids/did_core.dart';
import 'package:web5/src/dids/did_dht/dns_packet.dart';
import 'package:web5/src/dids/did_method_resolver.dart';
import 'package:web5/src/encoders.dart';
import 'package:web5/src/encoders/zbase.dart';

final Set<String> txtEntryNames = {'vm', 'auth', 'asm', 'agm', 'inv', 'del'};

enum DidDhtRegisteredDidType {
  /// Type 0 is reserved for DIDs that do not wish to associate themselves
  /// with a specific type but wish to make themselves discoverable.
  discoverable,

  /// Organization: https://schema.org/Organization
  organization,

  /// Government Organization: https://schema.org/GovernmentOrganization
  government,

  /// Corporation: https://schema.org/Corporation
  corporation,

  /// Local Business: https://schema.org/LocalBusiness
  localBusiness,

  /// Software Package: https://schema.org/SoftwareSourceCode
  softwarePackage,

  /// Web App: https://schema.org/WebApplication
  webApp,

  /// Financial Institution: https://schema.org/FinancialService
  financialInstitution,
}

class DidDht {
  static const String methodName = 'dht';

  static final resolver = DidMethodResolver(name: methodName, resolve: resolve);

  static Future<BearerDid> create({
    List<String>? alsoKnownAs,
    List<String>? controllers,
    String? gatewayUri,
    bool? publish,
    List<DidService>? services,
    List<DidDhtRegisteredDidType>? types,
    List<DidVerificationMethod>? verificationMethods,
  }) async {
    // Generate random key material for the Identity Key.
    final Jwk identityKeyUri = await Ed25519.generatePrivateKey();
    final Jwk identityKey = await Ed25519.computePublicKey(identityKeyUri);

    final String didUri = identityKeyToIdentifier(identityKey: identityKey);
    final DidDocument doc = DidDocument(
      id: didUri,
      alsoKnownAs: alsoKnownAs,
      controller: controllers,
    );

    return BearerDid(
      uri: didUri,
      keyManager: InMemoryKeyManager(),
      document: doc,
    );
  }

  static String identityKeyToIdentifier({
    required Jwk identityKey,
  }) {
    // Convert the key from JWK format to a byte array.
    final Uint8List publicKeyBytes = Ed25519.publicKeyToBytes(
      publicKey: identityKey,
    );

    final String identifier = ZBase32.encode(publicKeyBytes);
    return 'did:${DidDht.methodName}:$identifier';
  }

  static Future<DidResolutionResult> resolve(
    Did did, {
    String relayUrl = 'https://diddht.tbddev.org',
  }) async {
    if (did.method != methodName) {
      return DidResolutionResult.invalidDid();
    }

    final parsedRelayUrl = Uri.parse(relayUrl);
    final resolutionUrl = parsedRelayUrl.replace(path: did.id);

    final httpClient = HttpClient();
    final request = await httpClient.getUrl(resolutionUrl);
    final response = await request.close();

    final List<int> bytes = [];
    // Listening for response data
    await for (var byteList in response) {
      bytes.addAll(byteList);
    }

    httpClient.close(force: false);

    // TODO: verify signature
    // final signatureBytes = bytes.sublist(0, 64);
    // final seq = bytes.sublist(64, 72);

    if (bytes.length < 72) {
      return DidResolutionResult.invalidDid();
    }

    final v = bytes.sublist(72);

    final dnsPacket = DnsPacket.decode(v);
    final Map<String, List<String>> txtMap = {};
    List<String>? rootRecord;

    for (final answer in dnsPacket.answers) {
      if (answer.type != DnsType.TXT) {
        continue;
      }

      final txtData = answer.data as DnsTxtData;

      if (answer.name.value.startsWith('_did')) {
        rootRecord = txtData.value;
        continue;
      }

      txtMap[answer.name.value] = txtData.value;
    }

    if (rootRecord == null) {
      // TODO: figure out more appopriate resolution error to use.
      return DidResolutionResult.invalidDid();
    }

    final Map<String, List<String>> relationshipsMap = {};
    for (final entry in rootRecord[0].split(';')) {
      final splitEntry = entry.split('=');

      if (splitEntry.length != 2) {
        // TODO: figure out more appopriate resolution error to use.
        return DidResolutionResult.invalidDid();
      }

      final [property, values] = splitEntry;
      final splitValues = values.split(',');

      if (!txtEntryNames.contains(property)) {
        continue;
      }

      for (final value in splitValues) {
        relationshipsMap[value] ??= [];
        relationshipsMap[value]!.add(property);
      }
    }

    final didDocument = DidDocument(id: did.uri);
    for (final property in txtMap.entries) {
      final values = property.value[0].split(',');
      final valueMap = {};

      for (var value in values) {
        final [k, v] = value.split('=');
        valueMap[k] = v;
      }

      if (property.key.startsWith('_k')) {
        AlgorithmId algId;
        switch (valueMap['t']) {
          case '0':
            algId = AlgorithmId.ed25519;
            break;
          case '1':
            algId = AlgorithmId.secp256k1;
            break;
          default:
            throw Exception('unsupported algorithm type: ${valueMap['t']}');
        }

        final publicKeyBytes = Base64Url.decode(valueMap['k']);
        final publicKeyJwk = Crypto.bytesToPublicKey(algId, publicKeyBytes);
        final verificationMethod = DidVerificationMethod(
          controller: did.uri,
          id: valueMap['id'],
          type: 'JsonWebKey2020',
          publicKeyJwk: publicKeyJwk,
        );

        didDocument.addVerificationMethod(verificationMethod);
        final entryId = property.key.substring(1).split('.')[0];
        final relationships = relationshipsMap[entryId];

        if (relationships == null) {
          continue;
        }

        for (final relationship in relationships) {
          VerificationPurpose? vr;
          if (relationship == 'auth') {
            vr = VerificationPurpose.authentication;
          } else if (relationship == 'asm') {
            vr = VerificationPurpose.assertionMethod;
          } else if (relationship == 'agm') {
            vr = VerificationPurpose.keyAgreement;
          } else if (relationship == 'inv') {
            vr = VerificationPurpose.capabilityInvocation;
          } else if (relationship == 'del') {
            vr = VerificationPurpose.capabilityDelegation;
          }

          if (vr != null) {
            didDocument.addVerificationPurpose(vr, verificationMethod.id);
          }
        }
      } else if (property.key.startsWith('_s')) {
        final service = DidService(
          id: valueMap['id'],
          type: valueMap['t'],
          serviceEndpoint: valueMap['uri'],
        );

        didDocument.addService(service);
      }
    }

    return DidResolutionResult(didDocument: didDocument);
  }
}
