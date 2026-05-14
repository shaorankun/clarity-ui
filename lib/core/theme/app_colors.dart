import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background    = Color(0xFF0F0F1A);
  static const Color surface       = Color(0xFF1A1A2E);
  static const Color surfaceLight  = Color(0xFF22223B);

  // Primary
  static const Color primary       = Color(0xFF5C4AE4);
  static const Color primaryLight  = Color(0xFF7B6CF0);

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9090B0);
  static const Color textMuted     = Color(0xFF5A5A7A);

  // Accent
  static const Color success       = Color(0xFF4CAF50);
  static const Color warning       = Color(0xFFFFB74D);
  static const Color danger        = Color(0xFFEF5350);
  static const Color breakColor    = Color(0xFF26C6DA);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5C4AE4), Color(0xFF9C6FE4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F0F1A), Color(0xFF1A1228)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}