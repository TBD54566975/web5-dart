import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'web5_flutter_method_channel.dart';

abstract class Web5FlutterPlatform extends PlatformInterface {
  /// Constructs a Web5FlutterPlatform.
  Web5FlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static Web5FlutterPlatform _instance = MethodChannelWeb5Flutter();

  /// The default instance of [Web5FlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelWeb5Flutter].
  static Web5FlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [Web5FlutterPlatform] when
  /// they register themselves.
  static set instance(Web5FlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
