import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app_bootstrap.dart';
import 'app/app_config.dart';
import 'pages/auth/presentation/app_entry_page.dart';
import 'pages/auth/presentation/app_loading_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(bootstrapFuture: _bootstrapApp()));
}

Future<AppBootstrap> _bootstrapApp() async {
  await _initializeFirebase();

  final AppConfig config = AppConfig.fromEnvironment();
  return AppBootstrapper(config: config).bootstrap();
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    AppBootstrap? bootstrap,
    Future<AppBootstrap>? bootstrapFuture,
  }) : _bootstrap = bootstrap,
       _bootstrapFuture = bootstrapFuture;

  final AppBootstrap? _bootstrap;
  final Future<AppBootstrap>? _bootstrapFuture;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'MindfulConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF0A0B14),
        useMaterial3: true,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        textTheme: Typography.whiteMountainView.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    final AppBootstrap? bootstrap = _bootstrap;
    if (bootstrap != null) {
      return AppEntryPage(bootstrap: bootstrap);
    }

    return FutureBuilder<AppBootstrap>(
      future: _bootstrapFuture,
      builder: (BuildContext context, AsyncSnapshot<AppBootstrap> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppLoadingPage(message: '앱 환경을 준비하고 있어요.');
        }

        if (snapshot.hasError) {
          return AppEntryPage(
            bootstrap: AppBootstrap.failed(
              config: AppConfig.fromEnvironment(),
              errorMessage: snapshot.error.toString(),
            ),
          );
        }

        return AppEntryPage(bootstrap: snapshot.data!);
      },
    );
  }
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  }
}
