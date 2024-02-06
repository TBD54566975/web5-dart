import 'dart:convert';
import 'dart:io';

import 'package:web5/src/crypto/key_manager.dart';
import 'package:web5/src/dids/data_models.dart';
import 'package:web5/src/dids/did.dart';
import 'package:web5/src/dids/did_method_resolver.dart';
import 'package:web5/src/dids/did_uri.dart';

class DidWeb implements Did {
  @override
  // TODO: implement keyManager
  KeyManager get keyManager => throw UnimplementedError();

  @override
  // TODO: implement uri
  String get uri => throw UnimplementedError();

  static const String methodName = 'web';

  static final resolver = DidMethodResolver(name: methodName, resolve: resolve);

  static Future<DidResolutionResult> resolve(String didUri) async {
    final DidUri parsedDidUri;

    try {
      parsedDidUri = DidUri.parse(didUri);
    } on Exception {
      return DidResolutionResult.invalidDid();
    }

    if (parsedDidUri.method != methodName) {
      return DidResolutionResult.invalidDid();
    }

    // TODO: http technically not supported. remove after temp use
    var resolutionUrl = parsedDidUri.id.replaceAll(':', '/');
    if (resolutionUrl.contains('localhost')) {
      resolutionUrl = 'http://$resolutionUrl';
    } else {
      resolutionUrl = 'https://$resolutionUrl';
    }

    if (parsedDidUri.path != null) {
      resolutionUrl = '$resolutionUrl/${parsedDidUri.path}';
    } else {
      resolutionUrl = '$resolutionUrl/.well-known';
    }

    resolutionUrl += '/did.json';
    resolutionUrl = Uri.decodeFull(resolutionUrl);

    final parsedUrl = Uri.parse(resolutionUrl);

    final httpClient = HttpClient();
    final request = await httpClient.getUrl(parsedUrl);
    final response = await request.close();

    if (response.statusCode != 200) {
      // TODO: change this to something more appropriate
      return DidResolutionResult.invalidDid();
    }

    final str = await response.transform(utf8.decoder).join();
    final jsonParsed = json.decode(str);
    final doc = DidDocument.fromJson(jsonParsed);

    return DidResolutionResult(didDocument: doc);
  }
}
