import 'dart:convert';
import 'dart:typed_data';

enum Token {
  dict('d', 100),
  integer('i', 105),
  list('l', 108),
  end('e', 101);

  final String value;
  final int byte;

  const Token(this.value, this.byte);
}

class Bencoder {
  // Encodes various Dart types into Bencoded format
  static String bencode(dynamic input) {
    if (input is String) {
      return '${input.length}:$input';
    } else if (input is int) {
      return '${Token.integer.value}$input${Token.end.value}';
    } else if (input is Uint8List) {
      final str = utf8.decode(input);
      return bencode(str);
    } else {
      throw FormatException('Unsupported type: ${input.runtimeType}');
    }
  }
}
