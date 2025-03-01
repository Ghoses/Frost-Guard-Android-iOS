import 'package:flutter/material.dart';

class ThemeConstants {
  // Light Theme Colors
  static const Color primaryColorLight = Color(0xFF0A84FF);
  static const Color accentColorLight = Color(0xFF30D158);
  static const Color backgroundColorLight = Color(0xFFF2F2F7);
  static const Color surfaceColorLight = Colors.white;
  static const Color inputBackgroundColorLight = Color(0xFFE9E9EB);
  
  // Dark Theme Colors
  static const Color primaryColorDark = Color(0xFF0A84FF);
  static const Color accentColorDark = Color(0xFF30D158);
  static const Color backgroundColorDark = Color(0xFF1C1C1E);
  static const Color surfaceColorDark = Color(0xFF2C2C2E);
  static const Color inputBackgroundColorDark = Color(0xFF3A3A3C);
  
  // Frost Warning Colors
  static const Color frostWarningColor = Color(0xFFFF453A);
  static const Color frostWarningLightColor = Color(0xFFFFE5E3);
  static const Color frostWarningDarkColor = Color(0xFF3A0900);
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration normalAnimationDuration = Duration(milliseconds: 300);
  
  // UI Sizing
  static const double cardBorderRadius = 16.0;
  static const double inputBorderRadius = 12.0;
  static const double buttonBorderRadius = 12.0;
  
  // Padding & Spacing
  static const double smallPadding = 8.0;
  static const double normalPadding = 16.0;
  static const double largePadding = 24.0;
}
