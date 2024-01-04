import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tbdex_flutter_platform_interface.dart';

/// An implementation of [TbdexFlutterPlatform] that uses method channels.
class MethodChannelTbdexFlutter extends TbdexFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tbdex_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
