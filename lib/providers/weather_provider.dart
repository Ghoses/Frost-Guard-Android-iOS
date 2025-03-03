import 'package:flutter/material.dart';
import 'package:frost_guard/core/services/weather_service.dart';
import 'package:frost_guard/core/services/notification_service.dart';
import 'package:frost_guard/models/location.dart';
import 'package:frost_guard/models/weather_data.dart';
import 'package:frost_guard/providers/location_provider.dart';
import 'package:frost_guard/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final NotificationService _notificationService = NotificationService();
  
  // Für den Zugriff auf gespeicherte Einstellungen
  SettingsProvider? _settingsProvider;
  LocationProvider? _locationProvider;
  
  final Map<String, WeatherData> _weatherData = {};
  final Map<String, bool> _hasFrostWarning = {};
  final Map<String, double> _lowestTemperatures = {};
  
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;
  
  // Konstruktor mit Registrierung für Frost-Überprüfung
  WeatherProvider() {
    // Registriere den Callback für die Frost-Überprüfung
    NotificationService.setFrostCheckCallback(() {
      checkForFrost();
    });
  }
  
  // Initialisiere die Provider mit übergebenem Kontext
  void initializeProviders(BuildContext context) {
    try {
      _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      _locationProvider = Provider.of<LocationProvider>(context, listen: false);
    } catch (e) {
      print('Fehler bei der Provider-Initialisierung: $e');
    }
  }
  
  // Getter für SettingsProvider mit Null-Check
  SettingsProvider? get settingsProvider => _settingsProvider;
  
  // Getter für LocationProvider mit Null-Check
  LocationProvider? get locationProvider => _locationProvider;
  
  bool get isLoading => _isLoading;
  String? get error => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  
  // Wetterdaten für einen bestimmten Standort abrufen
  WeatherData getWeatherFor(String locationId) {
    return _weatherData[locationId] ?? WeatherData.empty();
  }
  
  // Prüft, ob für einen Standort eine Frostwarnung vorliegt
  bool hasFrostWarning(String locationId) {
    return _hasFrostWarning[locationId] ?? false;
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
      _hasFrostWarning[location.id] = willFreeze;
      
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
  
  // Tägliche Frost-Überprüfung durchführen
  Future<void> checkForFrost() async {
    if (_isLoading) {
      return;
    }
    
    // Prüfe, ob der SettingsProvider initialisiert wurde
    if (_settingsProvider == null || _locationProvider == null) {
      return;
    }
    
    // Hole alle gespeicherten Standorte
    final locations = _locationProvider?.locations;
    
    if (locations == null || locations.isEmpty) {
      return;
    }
    
    _setLoading(true);
    
    try {
      // Hole den konfigurierten Schwellenwert
      final threshold = _settingsProvider?.temperatureThreshold;
      
      // Überprüfe jeden Standort auf Frost
      for (final location in locations) {
        // Aktualisiere Wetterdaten für diesen Standort
        await updateForecast(location, threshold ?? 0.0, true);
      }
    } finally {
      _setLoading(false);
    }
  }
  
  // Hilfsmethoden
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
}
