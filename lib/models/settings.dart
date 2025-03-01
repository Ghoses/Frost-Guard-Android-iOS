import 'package:frost_guard/core/constants/app_constants.dart';

class Settings {
  final bool isDarkMode;
  final double temperatureThreshold;
  final bool notificationsEnabled;
  final String temperatureUnit;
  final int checkHour;
  final int checkMinute;

  Settings({
    this.isDarkMode = AppConstants.DEFAULT_DARK_MODE,
    this.temperatureThreshold = AppConstants.DEFAULT_TEMPERATURE_THRESHOLD,
    this.notificationsEnabled = AppConstants.DEFAULT_NOTIFICATIONS_ENABLED,
    this.temperatureUnit = AppConstants.DEFAULT_TEMPERATURE_UNIT,
    this.checkHour = AppConstants.DEFAULT_CHECK_HOUR,
    this.checkMinute = AppConstants.DEFAULT_CHECK_MINUTE,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      isDarkMode: json[AppConstants.KEY_DARK_MODE] ?? AppConstants.DEFAULT_DARK_MODE,
      temperatureThreshold: json[AppConstants.KEY_TEMPERATURE_THRESHOLD] ?? AppConstants.DEFAULT_TEMPERATURE_THRESHOLD,
      notificationsEnabled: json[AppConstants.KEY_NOTIFICATIONS_ENABLED] ?? AppConstants.DEFAULT_NOTIFICATIONS_ENABLED,
      temperatureUnit: json[AppConstants.KEY_TEMPERATURE_UNIT] ?? AppConstants.DEFAULT_TEMPERATURE_UNIT,
      checkHour: json[AppConstants.KEY_CHECK_HOUR] ?? AppConstants.DEFAULT_CHECK_HOUR,
      checkMinute: json[AppConstants.KEY_CHECK_MINUTE] ?? AppConstants.DEFAULT_CHECK_MINUTE,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.KEY_DARK_MODE: isDarkMode,
      AppConstants.KEY_TEMPERATURE_THRESHOLD: temperatureThreshold,
      AppConstants.KEY_NOTIFICATIONS_ENABLED: notificationsEnabled,
      AppConstants.KEY_TEMPERATURE_UNIT: temperatureUnit,
      AppConstants.KEY_CHECK_HOUR: checkHour,
      AppConstants.KEY_CHECK_MINUTE: checkMinute,
    };
  }

  Settings copyWith({
    bool? isDarkMode,
    double? temperatureThreshold,
    bool? notificationsEnabled,
    String? temperatureUnit,
    int? checkHour,
    int? checkMinute,
  }) {
    return Settings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      temperatureThreshold: temperatureThreshold ?? this.temperatureThreshold,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      checkHour: checkHour ?? this.checkHour,
      checkMinute: checkMinute ?? this.checkMinute,
    );
  }
}
