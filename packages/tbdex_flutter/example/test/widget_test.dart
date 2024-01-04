import 'package:flutter_test/flutter_test.dart';

import 'package:tbdex_flutter_example/main.dart';

void main() {
  testWidgets('Verify example app launch', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
  });
}
