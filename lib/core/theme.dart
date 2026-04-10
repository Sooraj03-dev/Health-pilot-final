import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:health_pilot/core/constants.dart';

/// Centralised Material 3 theme for Health Pilot.
abstract final class AppTheme {
  // ── Light theme ───────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: AppColors.primaryDark,
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: AppColors.textPrimary,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  // ── Dark theme (placeholder – app enforces light) ─────────────────────────
  static ThemeData get dark => light.copyWith(
        brightness: Brightness.dark,
      );
=======

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
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
}
