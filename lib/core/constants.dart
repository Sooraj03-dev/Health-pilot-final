import 'package:flutter/material.dart';

/// Design-reference colour constants for Health Pilot.
abstract final class AppColors {
  // ── Primary teal / green palette ──────────────────────────────────────────
  static const Color primaryDark = Color(0xFF1A7A5E);
  static const Color primary = Color(0xFF2E9B7F);
  static const Color primaryLight = Color(0xFF3EB489);

  // ── Background ────────────────────────────────────────────────────────────
  /// Light mint / pale blue — design reference #E8F4F4.
  static const Color scaffoldBg = Color(0xFFE8F4F4);
  static const Color cardBg = Colors.white;

  // ── SOS ────────────────────────────────────────────────────────────────────
  static const Color sosRed = Color(0xFFE53935);

  // ── Status badges ─────────────────────────────────────────────────────────
  static const Color normal = Color(0xFF2E9B7F);
  static const Color warning = Color(0xFFFF9800);
  static const Color critical = Color(0xFFE53935);

  // ── Neutrals ──────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}
