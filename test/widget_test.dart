import 'package:flutter_test/flutter_test.dart';
import 'package:neon_noir/src/app.dart';

void main() {
  testWidgets('Neon Noir app basic build test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NeonNoirApp());

    // Verify that the logo text exists.
    expect(find.text('NEON NOIR'), findsOneWidget);
  });
}
