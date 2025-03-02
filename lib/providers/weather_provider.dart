import 'package:flutter/material.dart';
import 'package:frost_guard/core/services/weather_service.dart';
import 'package:frost_guard/core/services/notification_service.dart';
import 'package:frost_guard/models/location.dart';
import 'package:frost_guard/models/weather_data.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final NotificationService _notificationService = NotificationService();
  
  final Map<String, WeatherData> _weatherData = {};
  final Map<String, bool> _frostWarnings = {};
  final Map<String, double> _lowestTemperatures = {};
  
  bool _isLoading = false;
  String _error = '';
  DateTime? _lastUpdated;
  
  bool get isLoading => _isLoading;
  String get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  
  // Wetterdaten für einen bestimmten Standort abrufen
  WeatherData getWeatherFor(String locationId) {
    return _weatherData[locationId] ?? WeatherData.empty();
  }
  
  // Prüft, ob für einen Standort eine Frostwarnung vorliegt
  bool hasFrostWarning(String locationId) {
    return _frostWarnings[locationId] ?? false;
  }
  
  // Gibt die niedrigste Temperatur für heute Nacht zurück
  double getLowestTemperature(String locationId) {
    return _lowestTemperatures[locationId] ?? 0.0;
  }
  
  // Wetterdaten für einen einzelnen Standort aktualisieren
  Future<void> updateForecast(Location location, double threshold, bool notificationsEnabled) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Wetterdaten abrufen
      final weatherData = await _weatherService.getForecast(
        location.latitude, 
        location.longitude
      );
      _weatherData[location.id] = weatherData;
      
      // Prüfe auf Frostgefahr
      final willFreeze = await _weatherService.willFreezeTonightAt(
        location.latitude, 
        location.longitude, 
        threshold
      );
      _frostWarnings[location.id] = willFreeze;
      
      // Ermittle die niedrigste Temperatur
      final lowestTemp = await _weatherService.getLowestTonightTemperature(
        location.latitude, 
        location.longitude
      );
      _lowestTemperatures[location.id] = lowestTemp;
      
      // Zeige Benachrichtigung, wenn Frost zu erwarten ist und Benachrichtigungen aktiviert sind
      if (willFreeze && notificationsEnabled) {
        await _notificationService.showFrostWarningNotification(
          location.name, 
          lowestTemp
        );
      }
      
      // Aktualisiere den Zeitstempel der letzten Aktualisierung
      _lastUpdated = DateTime.now();
      
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Aktualisieren der Wetterdaten für ${location.name}: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Wetterdaten für alle Standorte aktualisieren
  Future<void> updateAllForecasts(List<Location> locations, {
    double threshold = 3.0,
    bool notificationsEnabled = true,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      for (final location in locations) {
        await updateForecast(location, threshold, notificationsEnabled);
      }
    } finally {
      _setLoading(false);
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  
  void _clearError() {
    _error = '';
    notifyListeners();
  }
}
