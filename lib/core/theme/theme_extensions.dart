import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

extension AppThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground => isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
  Color get appCardBackground => isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
  Color get appCardHighlight => isDarkMode ? AppColors.darkCardHighlight : AppColors.lightCardHighlight;
  Color get appBorder => isDarkMode ? AppColors.darkBorder : AppColors.lightBorder;
  Color get appTextPrimary => isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get appTextSecondary => isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get appTextMuted => isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted;

  // اللون الأساسي النشط (أخضر رياضي في النهاري / برتقالي في الليلي)
  Color get appPrimary => isDarkMode ? AppColors.primaryOrange : AppColors.primaryGreen;
  Color get appPrimaryLight => isDarkMode ? AppColors.primaryOrange : AppColors.primaryGreenLight;

  List<BoxShadow> get appCardShadow => [
    BoxShadow(
      color: isDarkMode
          ? Colors.black.withOpacity(0.25)
          : const Color(0xFF1B7A36).withOpacity(0.06),
      blurRadius: 12,
      spreadRadius: 0,
      offset: const Offset(0, 3),
    ),
  ];
}
