import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app_bootstrap.dart';
import 'app/app_config.dart';
import 'pages/auth/presentation/app_entry_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();

  final AppConfig config = AppConfig.fromEnvironment();
  final AppBootstrap bootstrap = await AppBootstrapper(
    config: config,
  ).bootstrap();

  runApp(MyApp(bootstrap: bootstrap));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

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
      home: AppEntryPage(bootstrap: bootstrap),
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
