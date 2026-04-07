import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class MindrouterApp extends StatelessWidget {
  const MindrouterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mindrouter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}

