import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/app/app_bootstrap.dart';
import 'package:mindfulconnect/app/app_config.dart';
import 'package:mindfulconnect/main.dart';

void main() {
  testWidgets('missing config boot screen renders guidance', (
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

    expect(find.text('MindfulConnect'), findsOneWidget);
    expect(find.text('Supabase 설정이 필요합니다.'), findsOneWidget);
    expect(find.text('Config Needed'), findsOneWidget);
  });
}
