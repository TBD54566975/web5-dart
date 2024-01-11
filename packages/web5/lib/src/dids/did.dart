import 'package:web5/src/crypto.dart';

abstract class Did {
  String get uri;
  KeyManager get keyManager;
}
