import 'package:flutter/material.dart';

/// Centralized color constants for the PadalPro app
/// Use these instead of defining colors locally in each page
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFFE0F74D);
  static const Color primaryText = Color(0xFF111111);

  // Text Colors
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFFA3A3A3);
  static const Color textWhite = Colors.white;

  // Background Colors
  static const Color background = Color(0xFFEDF0F6);
  static const Color surface = Colors.white;

  // Status Colors
  static const Color error = Color(0xFFF74D50);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);

  // Other Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color overlay = Colors.black54;
}
