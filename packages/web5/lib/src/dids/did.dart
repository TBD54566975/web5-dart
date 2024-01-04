import 'package:web5/src/crypto/key_manager.dart';

abstract class Did {
  String get uri;
  KeyManager get keyManager;
}
