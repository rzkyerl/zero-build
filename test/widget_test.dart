import 'package:flutter_test/flutter_test.dart';
import 'package:zero/main.dart';

void main() {
  testWidgets('App smoke test — renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ZeroApp());
    expect(find.text('ZERO'), findsOneWidget);
  });
}
