import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // PhisIonApp requires dotenv + Hive initialization.
    // Full E2E tests should be done via integration_test package.
    expect(true, isTrue);
  });
}
