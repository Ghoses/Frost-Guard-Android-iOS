import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:frost_guard/core/constants/api_constants.dart';
import 'package:frost_guard/models/weather_data.dart';
import 'package:frost_guard/core/errors/exceptions.dart';
import 'package:frost_guard/core/utils/date_utils.dart';

class WeatherService {
  final String apiKey = dotenv.env['OPENWEATHERMAP_API_KEY'] ?? '';
  
  Future<WeatherData> getForecast(double lat, double lon) async {
    try {
      final url = '${ApiConstants.WEATHER_BASE_URL}${ApiConstants.ONECALL_ENDPOINT}?${ApiConstants.PARAM_LAT}=$lat&${ApiConstants.PARAM_LON}=$lon&${ApiConstants.PARAM_UNITS}=${ApiConstants.UNITS_METRIC}&${ApiConstants.PARAM_APP_ID}=$apiKey';
      
      print('API Request URL: $url'); // Debug-Ausgabe der URL
      
      final response = await http.get(Uri.parse(url));
      
      print('API Response Status: ${response.statusCode}'); // Debug-Ausgabe des Status-Codes
      print('API Response Body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...'); // Debug-Ausgabe der Antwort (gekürzt)
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw WeatherException('Fehler beim Abrufen der Wetterdaten: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw WeatherException('Netzwerkfehler: $e');
    }
  }
  
  // Ermittelt, ob heute Nacht Frost zu erwarten ist
  Future<bool> willFreezeTonightAt(double lat, double lon, double threshold) async {
    final forecast = await getForecast(lat, lon);
    
    // Filtere die heutigen Nachtzeiten (18:00 - 06:00 Uhr)
    final tonightHours = forecast.hourly.where((hour) {
      final dateTime = DateTimeUtils.fromUnixTimestamp(hour.dt);
      return DateTimeUtils.isNightTime(dateTime) && 
             (DateTimeUtils.isToday(dateTime) || 
              DateTimeUtils.isTomorrow(dateTime));
    }).toList();
    
    // Prüfe, ob eine der Temperaturen unter dem Schwellenwert liegt
    return tonightHours.any((hour) => hour.temp < threshold);
  }
  
  // Findet die niedrigste Temperatur für heute Nacht
  Future<double> getLowestTonightTemperature(double lat, double lon) async {
    final forecast = await getForecast(lat, lon);
    
    // Filtere die heutigen Nachtzeiten (18:00 - 06:00 Uhr)
    final tonightHours = forecast.hourly.where((hour) {
      final dateTime = DateTimeUtils.fromUnixTimestamp(hour.dt);
      return DateTimeUtils.isNightTime(dateTime) && 
             (DateTimeUtils.isToday(dateTime) || 
              DateTimeUtils.isTomorrow(dateTime));
    }).toList();
    
    if (tonightHours.isEmpty) {
      return 0.0;
    }
    
    // Finde die niedrigste Temperatur
    double lowestTemp = tonightHours.first.temp;
    for (var hour in tonightHours) {
      if (hour.temp < lowestTemp) {
        lowestTemp = hour.temp;
      }
    }
    
    return lowestTemp;
  }
  
  // Hilfsmethode zum Abrufen der Wetter-Icon-URL
  String getWeatherIconUrl(String iconCode) {
    return '${ApiConstants.ICON_URL}$iconCode${ApiConstants.ICON_SUFFIX}';
  }
}
