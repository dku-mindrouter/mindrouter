import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/pages/constellation/presentation/constellation_page.dart';

void main() {
  testWidgets(
    'preview constellation summarizes feed tags and shows all tags in detail',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConstellationPage(
              userId: 'someone-else',
              isPreviewMode: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('#외로움 +2'), findsOneWidget);
      expect(find.text('#지침 +1'), findsOneWidget);

      await tester.tap(find.text('#외로움 +2'));
      await tester.pumpAndSettle();

      expect(find.text('#외로움'), findsNWidgets(2));
      expect(find.text('#위로받고 싶음'), findsNWidgets(2));
      expect(find.text('#불안'), findsNWidgets(2));
    },
  );
}
