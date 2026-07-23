import 'package:flutter/material.dart';

/// 双人时光主题：粉色调，温暖治愈
class AppTheme {
  static const Color primary = Color(0xFFFF8C9E);
  static const Color primaryLight = Color(0xFFFFB5C2);
  static const Color bgColor = Color(0xFFFFF0F0);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color cardBg = Colors.white;
  static const Color danger = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFF9800);
  static const Color success = Color(0xFF66BB6A);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bgColor,
        primaryColor: primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
        ),
      );
}
