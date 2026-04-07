import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF090B1B);
  static const Color surface = Color(0xFF13172A);
  static const Color surfaceAlt = Color(0xFF1A1F38);
  static const Color primary = Color(0xFF8B6CFF);
  static const Color secondary = Color(0xFF6FD2C8);
  static const Color accent = Color(0xFFF6C063);
  static const Color textPrimary = Color(0xFFF5F2FF);
  static const Color textMuted = Color(0xFF9BA3C7);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: textMuted,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceAlt,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF2D3152)),
        ),
      ),
    );
  }
}
