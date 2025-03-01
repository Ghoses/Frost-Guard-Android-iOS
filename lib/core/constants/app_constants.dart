class AppConstants {
  // App Settings Keys
  static const String KEY_DARK_MODE = 'isDarkMode';
  static const String KEY_TEMPERATURE_THRESHOLD = 'temperatureThreshold';
  static const String KEY_NOTIFICATIONS_ENABLED = 'notificationsEnabled';
  static const String KEY_TEMPERATURE_UNIT = 'temperatureUnit';
  static const String KEY_CHECK_HOUR = 'checkHour';
  static const String KEY_CHECK_MINUTE = 'checkMinute';
  static const String KEY_LOCATIONS = 'savedLocations';
  
  // App Default Values
  static const bool DEFAULT_DARK_MODE = true;
  static const double DEFAULT_TEMPERATURE_THRESHOLD = 3.0;
  static const bool DEFAULT_NOTIFICATIONS_ENABLED = true;
  static const String DEFAULT_TEMPERATURE_UNIT = 'celsius';
  static const int DEFAULT_CHECK_HOUR = 18;
  static const int DEFAULT_CHECK_MINUTE = 0;
  
  // Temperatureinheiten
  static const String temperatureUnitCelsius = 'celsius';
  static const String temperatureUnitFahrenheit = 'fahrenheit';
  
  // Notification Channel IDs
  static const String FROST_WARNING_CHANNEL_ID = 'frost_guard_channel';
  static const String DAILY_CHECK_CHANNEL_ID = 'frost_guard_daily';
  
  // Notification IDs
  static const int FROST_WARNING_ID = 1001;
  static const int DAILY_CHECK_ID = 1002;
}
