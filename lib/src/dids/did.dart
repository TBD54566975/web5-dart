import 'package:tbdex/src/crypto/key_manager.dart';

abstract class Did {
  String get uri;
  KeyManager get keyManager;
}
