import 'package:flutter_test/flutter_test.dart';

import 'package:web5_flutter_example/main.dart';

void main() {
  testWidgets('Verify example app launch', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
  });
}
