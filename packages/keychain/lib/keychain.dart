import 'package:flutter/services.dart';

class Keychain {
  static const MethodChannel _channel = MethodChannel('web5.keychain');

  static Future<bool?> delete(String key) async {
    bool? result = await _channel.invokeMethod(
      'delete',
      {'key': key},
    );

    return result;
  }

  static Future<String?> fetch(String key) async {
    String? result = await _channel.invokeMethod(
      'fetch',
      {'key': key},
    );

    return result;
  }

  static Future<bool?> set(String key, String value) async {
    bool? result = await _channel.invokeMethod(
      'set',
      {'key': key, 'value': value},
    );

    return result;
  }
}
