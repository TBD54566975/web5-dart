import 'package:test/test.dart';
import 'package:web5/src/dids/did_web/did_web.dart';

void main() {
  group('DidWeb', () {
    test('should resolve successfully', () async {
      final result = await DidWeb.resolve('did:web:www.linkedin.com');
      expect(result.didDocument, isNotNull);

      expect('did:web:www.linkedin.com', result.didDocument!.id);
    });
  });
}
