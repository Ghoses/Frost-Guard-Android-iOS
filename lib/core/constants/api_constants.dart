class ApiConstants {
  // API Basis-URLs
  static const String WEATHER_BASE_URL = 'https://api.openweathermap.org/data/3.0';
  static const String GEOCODING_BASE_URL = 'https://api.openweathermap.org/geo/1.0';
  static const String ICON_URL = 'https://openweathermap.org/img/wn/';
  
  // API Endpunkte
  static const String ONECALL_ENDPOINT = '/onecall';
  static const String GEOCODING_ENDPOINT = '/direct';
  static const String REVERSE_GEOCODING_ENDPOINT = '/reverse';
  
  // API Parameter Keys
  static const String PARAM_LAT = 'lat';
  static const String PARAM_LON = 'lon';
  static const String PARAM_EXCLUDE = 'exclude';
  static const String PARAM_UNITS = 'units';
  static const String PARAM_APP_ID = 'appid';
  static const String PARAM_QUERY = 'q';
  static const String PARAM_LIMIT = 'limit';
  
  // API Parameter Values
  static const String UNITS_METRIC = 'metric';
  static const String EXCLUDE_MINUTELY = 'minutely';
  static const int DEFAULT_LOCATION_LIMIT = 5;
  
  // Konstanten für die Wetter-Icons
  static const String ICON_SUFFIX = '@2x.png';
}
