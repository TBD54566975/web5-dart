import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tbdex_flutter_method_channel.dart';

abstract class TbdexFlutterPlatform extends PlatformInterface {
  /// Constructs a TbdexFlutterPlatform.
  TbdexFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static TbdexFlutterPlatform _instance = MethodChannelTbdexFlutter();

  /// The default instance of [TbdexFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelTbdexFlutter].
  static TbdexFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TbdexFlutterPlatform] when
  /// they register themselves.
  static set instance(TbdexFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
