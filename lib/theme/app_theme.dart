import 'package:flutter/material.dart';

class KairosColors {
  static const Color primary = Color(0xFF00696F);
  static const Color primaryContainer = Color(0xFF00F2FE);
  static const Color onPrimary = Colors.white;
  static const Color surface = Color(0xFFF9F9FF);
  static const Color surfaceContainer = Color(0xFFE7EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDEE8FF);
  static const Color onSurface = Color(0xFF111C2D);
  static const Color onSurfaceVariant = Color(0xFF3A494B);
  static const Color outline = Color(0xFF6A7A7B);
  static const Color cyan = Color(0xFF00DCE6);
  static const Color cyanBright = Color(0xFF00F2FE);
  static const Color background = Color(0xFFF9F9FF);
  static const Color error = Color(0xFFBA1A1A);
}

class KairosTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: KairosColors.primary,
          primaryContainer: KairosColors.primaryContainer,
          onPrimary: KairosColors.onPrimary,
          surface: KairosColors.surface,
          onSurface: KairosColors.onSurface,
          onSurfaceVariant: KairosColors.onSurfaceVariant,
          outline: KairosColors.outline,
          error: KairosColors.error,
        ),
        scaffoldBackgroundColor: KairosColors.background,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: KairosColors.onSurface,
        ),
      );
}
