import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/app/app_bootstrap.dart';
import 'package:mindfulconnect/app/app_config.dart';
import 'package:mindfulconnect/main.dart';

void main() {
  testWidgets('missing config starts preview mode experience', (
    WidgetTester tester,
  ) async {
    final AppBootstrap bootstrap = AppBootstrap.missingConfig(
      config: const AppConfig(
        supabaseUrl: '',
        supabaseAnonKey: '',
        defaultTimezone: 'Asia/Seoul',
      ),
    );

    await tester.pumpWidget(MyApp(bootstrap: bootstrap));

    expect(find.text('안전한 우주 공간'), findsOneWidget);
    expect(find.text('Preview Mode'), findsOneWidget);
    expect(find.textContaining('Supabase 설정 없이'), findsOneWidget);
  });
}
