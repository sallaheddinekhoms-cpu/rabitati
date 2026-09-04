import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents
  static const Color primaryGreen = Color(0xFF1B7A36);
  static const Color primaryGreenLight = Color(0xFF2EB85C);
  static const Color primaryGreenDark = Color(0xFF135726);
  static const Color primaryOrange = Color(0xFFE8681A);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color errorRed = Color(0xFFDC2626);

  // Light Palette (الهوية الخضراء الرياضية المستوحاة من لوحة المحافظين)
  static const Color lightBackground = Color(0xFFF1F8F4);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightCardHighlight = Color(0xFFEAF5EE);
  static const Color lightBorder = Color(0xFFD6E8DE);
  static const Color lightTextPrimary = Color(0xFF14291E);
  static const Color lightTextSecondary = Color(0xFF527863);
  static const Color lightTextMuted = Color(0xFF8BA396);

  // Dark Palette
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCardBackground = Color(0xFF1E293B);
  static const Color darkCardHighlight = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Fallbacks
  static const Color background = darkBackground;
  static const Color cardBackground = darkCardBackground;
  static const Color cardHighlight = darkCardHighlight;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;
  static const Color border = darkBorder;
}
