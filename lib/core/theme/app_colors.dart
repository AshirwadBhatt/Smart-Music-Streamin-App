import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color primary        = Color(0xFF1DB954);
  static const Color primaryDark    = Color(0xFF158A3E);
  static const Color accent         = Color(0xFF7C4DFF);
  static const Color background     = Color(0xFF0A0A0A);
  static const Color surface        = Color(0xFF141414);
  static const Color surfaceVariant = Color(0xFF1E1E1E);
  static const Color card           = Color(0xFF242424);
  static const Color cardElevated   = Color(0xFF2A2A2A);
  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFFB3B3B3);
  static const Color textMuted      = Color(0xFF727272);
  static const Color divider        = Color(0xFF2A2A2A);
  static const Color error          = Color(0xFFE53935);
  static const Color success        = Color(0xFF1DB954);
  static const Color warning        = Color(0xFFFFA726);

  // Gradient presets used across screens
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1DB954), Color(0xFF0D7A35)],
  );
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0A)],
  );
  static const LinearGradient playerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E1E3F), Color(0xFF0A0A0A)],
  );
}
