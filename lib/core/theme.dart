import 'package:flutter/material.dart';

/// Health Pilot Material 3 theme.
///
/// Uses [ColorScheme.fromSeed] customized with the specific design tokens.
class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF0B6E4F); // teal-green

  // ── Light theme tokens ───────────────────────────────────────────────────
  static const _bgLight = Color(0xFFF5F6FA);
  static const _cardLight = Color(0xFFFFFFFF);
  static const _cardHoverLight = Color(0xFFF0F0F8);
  static const _textPrimaryLight = Color(0xFF1A1A2E);
  static const _textSecondaryLight = Color(0xFF6B6B8D);
  static const _borderLight = Color(0xFFE0E0EE);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: _bgLight,
    hoverColor: _cardHoverLight,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      surface: _bgLight,
      onSurface: _textPrimaryLight,
      onSurfaceVariant: _textSecondaryLight,
      outline: _borderLight,
      outlineVariant: _borderLight,
    ),
    cardTheme: const CardThemeData(
      color: _cardLight,
      elevation: 4.0,
      shadowColor: Color(0x0D000000), // subtle black opacity (~5%)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        side: BorderSide(color: _borderLight, width: 1.0),
      ),
    ),
    textTheme: const TextTheme().apply(
      bodyColor: _textPrimaryLight,
      displayColor: _textPrimaryLight,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _cardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        borderSide: BorderSide(color: _borderLight, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        borderSide: BorderSide(color: _borderLight, width: 1.0),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      labelStyle: TextStyle(color: _textSecondaryLight),
      hintStyle: TextStyle(color: _textSecondaryLight),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  // ── Dark theme tokens ────────────────────────────────────────────────────
  static const _bgDark = Color(0xFF0F0F1A);
  static const _cardDark = Color(0xFF1A1A2E);
  static const _cardHoverDark = Color(0xFF25253D);
  static const _borderDark = Color(0x0FFFFFFF); // white/6% opacity

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: _bgDark,
    hoverColor: _cardHoverDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      surface: _bgDark,
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFFB0B0B0),
      outline: _borderDark,
      outlineVariant: _borderDark,
    ),
    cardTheme: const CardThemeData(
      color: _cardDark,
      elevation: 4.0,
      shadowColor: Color(0x330B6E4F), // 20% opacity of seed color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        side: BorderSide(color: _borderDark, width: 1.0),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        borderSide: BorderSide(color: _borderDark, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        borderSide: BorderSide(color: _borderDark, width: 1.0),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
