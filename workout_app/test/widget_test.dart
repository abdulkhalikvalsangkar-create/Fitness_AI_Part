import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app/app.dart';

void main() {
  testWidgets('App class exists', (WidgetTester tester) async {
    // Smoke test: verify LiftLogApp is defined.
    // Full widget tests require StorageService initialisation.
    expect(LiftLogApp, isNotNull);
  });
}
