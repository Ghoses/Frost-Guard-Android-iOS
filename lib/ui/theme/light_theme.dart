import 'package:flutter/material.dart';
import 'package:frost_guard/core/constants/theme_constants.dart';

class LightTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: ThemeConstants.primaryColorLight,
      secondary: ThemeConstants.accentColorLight,
      surface: ThemeConstants.surfaceColorLight,
    ),
    scaffoldBackgroundColor: ThemeConstants.backgroundColorLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: ThemeConstants.surfaceColorLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.black),
    ),
    cardTheme: CardTheme(
      color: ThemeConstants.surfaceColorLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.cardBorderRadius),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ThemeConstants.surfaceColorLight,
      selectedItemColor: ThemeConstants.primaryColorLight,
      unselectedItemColor: Colors.grey,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ThemeConstants.inputBackgroundColorLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.inputBorderRadius),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.grey),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ThemeConstants.primaryColorLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.buttonBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ThemeConstants.primaryColorLight,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: ThemeConstants.primaryColorLight,
      thumbColor: ThemeConstants.primaryColorLight,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ThemeConstants.primaryColorLight;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ThemeConstants.primaryColorLight.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.5);
      }),
    ),
  );
}
