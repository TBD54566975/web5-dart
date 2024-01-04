import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'web5_flutter_platform_interface.dart';

/// An implementation of [Web5FlutterPlatform] that uses method channels.
class MethodChannelWeb5Flutter extends Web5FlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('web5_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
