import 'package:flutter/material.dart';
import 'package:frost_guard/core/services/weather_service.dart';
import 'package:frost_guard/core/services/notification_service.dart';
import 'package:frost_guard/models/location.dart';
import 'package:frost_guard/models/weather_data.dart';
import 'package:frost_guard/providers/location_provider.dart';
import 'package:frost_guard/providers/settings_provider.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final NotificationService _notificationService = NotificationService();
  
  final Map<String, WeatherData> _weatherData = {};
  final Map<String, bool> _hasFrostWarning = {};
  final Map<String, double> _lowestTemperatures = {};
  
  bool _isLoading = false;
  String _error = '';
  DateTime? _lastUpdated;
  
  // Konstruktor mit Registrierung für Frost-Überprüfung
  WeatherProvider() {
    // Registriere den Callback für die Frost-Überprüfung
    NotificationService.setFrostCheckCallback(() {
      debugPrint('Frost-Überprüfungs-Callback ausgelöst');
      checkForFrost();
    });
  }
  
  bool get isLoading => _isLoading;
  String get error => _error;
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
    debugPrint('==== FROST CHECK START: Führe geplante Frost-Überprüfung für alle Standorte durch ====');
    
    try {
      _setLoading(true);
      _clearError();
      
      // Hole alle Standorte aus dem LocationProvider
      final locationProvider = LocationProvider();
      await locationProvider.loadLocations();
      final locations = locationProvider.locations;
      
      debugPrint('Gefundene Standorte für Frost-Check: ${locations.length}');
      
      if (locations.isEmpty) {
        debugPrint('Keine Standorte für die Frost-Überprüfung gefunden');
        return;
      }
      
      // Hole die Einstellungen
      final settingsProvider = SettingsProvider();
      final threshold = settingsProvider.temperatureThreshold;
      final notificationsEnabled = settingsProvider.notificationsEnabled;
      
      debugPrint('Frost-Überprüfung mit Schwellenwert: ${threshold.toStringAsFixed(1)}°C, Benachrichtigungen: ${notificationsEnabled ? 'aktiviert' : 'deaktiviert'}');
      
      if (!notificationsEnabled) {
        debugPrint('Benachrichtigungen sind deaktiviert, überspringe Frost-Überprüfung');
        return;
      }
      
      // Aktualisiere die Vorhersagen für alle Standorte, erzwinge dabei eine Neuabfrage
      debugPrint('Aktualisiere Wetterdaten für alle Standorte...');
      await updateAllForecasts(
        locations, 
        threshold: threshold, 
        notificationsEnabled: notificationsEnabled
      );
      
      // Überprüfe jeden Standort auf Frost
      bool hasSentWarning = false;
      for (final location in locations) {
        final locationId = location.id;
        
        debugPrint('Überprüfe Standort: ${location.name} (ID: $locationId)');
        
        if (!_weatherData.containsKey(locationId)) {
          debugPrint('Keine Wetterdaten für Standort ${location.name} verfügbar');
          continue;
        }
        
        final weatherData = _weatherData[locationId]!;
        final lowestTemp = _getLowestTemperatureFromData(weatherData, locationId);
        
        debugPrint('Standort ${location.name}: Niedrigste Temperatur ${lowestTemp.toStringAsFixed(1)}°C, Schwellenwert ${threshold.toStringAsFixed(1)}°C');
        
        // Markiere die Karte als rot, wenn die Temperatur unter dem Schwellenwert liegt
        _hasFrostWarning[locationId] = lowestTemp <= threshold;
        
        // Sende eine Benachrichtigung, wenn Frost vorhergesagt wird
        if (lowestTemp <= threshold) {
          debugPrint('🚨 FROSTWARNUNG für ${location.name}: ${lowestTemp.toStringAsFixed(1)}°C');
          
          // Setze die niedrigste Temperatur für die Anzeige
          _lowestTemperatures[locationId] = lowestTemp;
          
          // Sende eine Benachrichtigung für diesen Standort
          await _notificationService.showFrostWarningNotification(location.name, lowestTemp);
          hasSentWarning = true;
        } else {
          debugPrint('✅ Kein Frost erwartet für ${location.name}');
        }
      }
      
      if (!hasSentWarning) {
        debugPrint('Keine Frostwarnungen für die überprüften Standorte erforderlich');
      } else {
        debugPrint('Frostwarnungen für einen oder mehrere Standorte gesendet');
      }
      
      // Aktualisiere den Zeitstempel der letzten Aktualisierung
      _lastUpdated = DateTime.now();
      notifyListeners();
      
      debugPrint('==== FROST CHECK END: Frost-Überprüfung abgeschlossen ====');
      
    } catch (e) {
      debugPrint('❌ FEHLER bei der Frost-Überprüfung: $e');
      _setError('Fehler bei der Frost-Überprüfung: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Überprüfe einen bestimmten Standort auf Frost
  Future<void> checkLocationForFrost(Location location, double threshold) async {
    try {
      debugPrint('Überprüfe Standort ${location.name} auf Frost');
      
      // Prüfe auf Frostgefahr
      final willFreeze = await _weatherService.willFreezeTonightAt(
        location.latitude, 
        location.longitude, 
        threshold
      );
      
      // Ermittle die niedrigste Temperatur
      final lowestTemp = await _weatherService.getLowestTonightTemperature(
        location.latitude, 
        location.longitude
      );
      
      // Aktualisiere die Daten
      _hasFrostWarning[location.id] = willFreeze;
      _lowestTemperatures[location.id] = lowestTemp;
      
      // Zeige Benachrichtigung, wenn Frost zu erwarten ist
      if (willFreeze) {
        debugPrint('Frostwarnung für ${location.name}: $lowestTemp°C');
        await _notificationService.showFrostWarningNotification(
          location.name, 
          lowestTemp
        );
      } else {
        debugPrint('Kein Frost für ${location.name} erwartet: $lowestTemp°C');
      }
    } catch (e) {
      debugPrint('Fehler bei der Frost-Überprüfung für Standort ${location.name}: $e');
    }
  }
  
  // Hilfsmethode, um die niedrigste Temperatur aus den Wetterdaten zu extrahieren
  double _getLowestTemperatureFromData(WeatherData weatherData, String locationId) {
    try {
      if (weatherData.hourly.isNotEmpty) {
        // Finde die niedrigste Temperatur in den nächsten 24 Stunden
        final temperatures = weatherData.hourly.map((h) => h.temp).toList();
        if (temperatures.isNotEmpty) {
          return temperatures.reduce((value, element) => value < element ? value : element);
        }
      }
      
      // Fallback auf die gespeicherte niedrigste Temperatur
      if (_lowestTemperatures.containsKey(locationId)) {
        return _lowestTemperatures[locationId]!;
      }
      
      // Wenn keine Daten verfügbar sind, gib einen Standardwert zurück
      return 999.0; // Sehr hoher Wert, damit keine Frostwarnung ausgelöst wird
    } catch (e) {
      debugPrint('Fehler beim Extrahieren der niedrigsten Temperatur: $e');
      return 999.0;
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
