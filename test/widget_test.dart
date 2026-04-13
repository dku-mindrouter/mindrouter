import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/main.dart';

void main() {
  testWidgets('boot screen renders key status text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('MindfulConnect'), findsOneWidget);
    expect(find.text('Boot Ready'), findsOneWidget);
    expect(
      find.text(
        'Frontend boot mode is ready on the backend-aligned branch.',
      ),
      findsOneWidget,
    );
  });
}
