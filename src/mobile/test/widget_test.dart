import 'package:flutter_test/flutter_test.dart';
import 'package:the_app/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const TheApp());
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
