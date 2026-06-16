import 'package:flutter/material.dart';

/// Central color palette. Dark, nightlife-friendly base with semantic colors
/// for the three safety states.
class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF0E0B14);
  static const Color surface = Color(0xFF1A1622);
  static const Color surfaceElevated = Color(0xFF241F30);
  static const Color border = Color(0xFF332C42);

  static const Color textPrimary = Color(0xFFF5F2FA);
  static const Color textSecondary = Color(0xFFA89FBC);

  static const Color primary = Color(0xFF8B5CF6); // violet accent
  static const Color primaryDark = Color(0xFF6D28D9);

  // Safety semantics
  static const Color safe = Color(0xFF22C55E);
  static const Color neutral = Color(0xFFF59E0B);
  static const Color notSafe = Color(0xFFEF4444);

  static const List<Color> prideGradient = [
    Color(0xFFE40303),
    Color(0xFFFF8C00),
    Color(0xFFFFED00),
    Color(0xFF008026),
    Color(0xFF24408E),
    Color(0xFF732982),
  ];
}
