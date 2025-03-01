import 'package:flutter/material.dart';
import 'package:frost_guard/core/constants/theme_constants.dart';

class DarkTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: ThemeConstants.primaryColorDark,
      secondary: ThemeConstants.accentColorDark,
      background: ThemeConstants.backgroundColorDark,
      surface: ThemeConstants.surfaceColorDark,
    ),
    scaffoldBackgroundColor: ThemeConstants.backgroundColorDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: ThemeConstants.surfaceColorDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: ThemeConstants.surfaceColorDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.cardBorderRadius),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ThemeConstants.surfaceColorDark,
      selectedItemColor: ThemeConstants.primaryColorDark,
      unselectedItemColor: Colors.grey,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ThemeConstants.inputBackgroundColorDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.inputBorderRadius),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.grey),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ThemeConstants.primaryColorDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.buttonBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ThemeConstants.primaryColorDark,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: ThemeConstants.primaryColorDark,
      thumbColor: ThemeConstants.primaryColorDark,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return ThemeConstants.primaryColorDark;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return ThemeConstants.primaryColorDark.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.5);
      }),
    ),
  );
}
