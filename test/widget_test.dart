import 'package:flutter_test/flutter_test.dart';
import 'package:lucky_king/src/app.dart';

void main() {
  testWidgets('Lucky King app basic build test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LuckyKingApp());

    // Verify that the logo text exists.
    expect(find.text('LUCKY KING'), findsOneWidget);
  });
}
