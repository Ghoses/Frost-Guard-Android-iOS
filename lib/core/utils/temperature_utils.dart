import 'package:frost_guard/core/constants/app_constants.dart';

class TemperatureUtils {
  // Formatiert eine Temperatur mit einer Nachkommastelle und °C/°F Symbol
  static String formatTemperature(double temperature, String unit) {
    final formattedTemp = temperature.toStringAsFixed(1);
    final symbol = unit == AppConstants.temperatureUnitCelsius ? '°C' : '°F';
    return '$formattedTemp$symbol';
  }
  
  // Konvertiert Celsius zu Fahrenheit
  static double celsiusToFahrenheit(double celsius) {
    return (celsius * 9 / 5) + 32;
  }
  
  // Konvertiert Fahrenheit zu Celsius
  static double fahrenheitToCelsius(double fahrenheit) {
    return (fahrenheit - 32) * 5 / 9;
  }
  
  // Gibt die richtige Temperatur basierend auf der ausgewählten Einheit zurück
  static double getTemperatureInUnit(double celsius, String unit) {
    if (unit == AppConstants.temperatureUnitCelsius) {
      return celsius;
    } else {
      return celsiusToFahrenheit(celsius);
    }
  }
  
  // Klassifiziert die Temperatur für die Farbcodierung
  static TemperatureCategory categorizeTemperature(double celsius) {
    if (celsius < 0) {
      return TemperatureCategory.freezing;
    } else if (celsius < 5) {
      return TemperatureCategory.cold;
    } else if (celsius < 15) {
      return TemperatureCategory.cool;
    } else if (celsius < 25) {
      return TemperatureCategory.moderate;
    } else if (celsius < 30) {
      return TemperatureCategory.warm;
    } else {
      return TemperatureCategory.hot;
    }
  }
}

enum TemperatureCategory {
  freezing,
  cold,
  cool,
  moderate,
  warm,
  hot,
}
