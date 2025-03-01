import 'package:flutter/material.dart';
import 'package:frost_guard/ui/theme/dark_theme.dart';
import 'package:frost_guard/ui/theme/light_theme.dart';

class AppTheme {
  static ThemeData get lightTheme => LightTheme.theme;
  static ThemeData get darkTheme => DarkTheme.theme;
}
