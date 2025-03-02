import 'package:flutter/material.dart';
import 'package:frost_guard/core/services/weather_service.dart';
import 'package:frost_guard/core/services/notification_service.dart';
import 'package:frost_guard/models/location.dart';
import 'package:frost_guard/models/weather_data.dart';
import 'package:frost_guard/providers/location_provider.dart';
import 'package:frost_guard/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:frost_guard/main.dart'; // Importiere navigatorKey aus main.dart

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
      debugPrint('Frost-Überprüfungs-Callback ausgelöst');
      checkForFrost();
    });
    
    // Provider werden erst später initialisiert, daher warten wir auf den ersten Frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }
  
  // Initialisiere die Provider, wenn der Kontext verfügbar ist
  void _initializeProviders() {
    try {
      if (navigatorKey.currentContext != null) {
        _settingsProvider = Provider.of<SettingsProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        _locationProvider = Provider.of<LocationProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        debugPrint('Provider erfolgreich initialisiert');
      }
    } catch (e) {
      debugPrint('Fehler bei der Provider-Initialisierung: $e');
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
    debugPrint('Starte Überprüfung auf Frost für alle Standorte');
    
    if (_isLoading) {
      debugPrint('Wetteraktualisierung läuft bereits, überspringe Überprüfung');
      return;
    }
    
    // Prüfe, ob der SettingsProvider initialisiert wurde
    if (_settingsProvider == null) {
      debugPrint('SettingsProvider ist nicht initialisiert, versuche erneut zu initialisieren');
      // Versuche, den SettingsProvider zu initialisieren, falls er noch nicht verfügbar ist
      try {
        if (navigatorKey.currentContext != null) {
          _settingsProvider = Provider.of<SettingsProvider>(
            navigatorKey.currentContext!,
            listen: false,
          );
        } else {
          debugPrint('Kein Kontext verfügbar, überspringe Überprüfung');
          return;
        }
      } catch (e) {
        debugPrint('Fehler beim Initialisieren des SettingsProvider: $e');
        return;
      }
    }
    
    // Hole alle gespeicherten Standorte
    final locations = _locationProvider?.locations;
    
    if (locations == null || locations.isEmpty) {
      debugPrint('Keine Standorte konfiguriert, überspringe Überprüfung');
      return;
    }
    
    _setLoading(true);
    
    try {
      debugPrint('Überprüfe ${locations.length} Standorte auf Frost');
      
      // Hole den konfigurierten Schwellenwert
      final threshold = _settingsProvider?.temperatureThreshold;
      debugPrint('Frostschwellenwert: $threshold°');
      
      // Überprüfe jeden Standort auf Frost
      for (final location in locations) {
        debugPrint('Überprüfe Standort: ${location.name}');
        
        // Aktualisiere Wetterdaten für diesen Standort
        await updateForecast(location, threshold ?? 0.0, true);
        
        if (!_weatherData.containsKey(location.id)) {
          debugPrint('Keine Wetterdaten für ${location.name} verfügbar, überspringe');
          continue;
        }
        
        // Ermittle die niedrigste Temperatur in den Vorhersagedaten
        final lowestTemp = _getLowestTemperatureFromData(_weatherData[location.id]!, location.id);
        debugPrint('Niedrigste Temperatur für ${location.name}: $lowestTemp°');
        
        // Ist die Temperatur unter dem Schwellenwert?
        if (lowestTemp <= (threshold ?? 0.0)) {
          debugPrint('Frost erkannt für ${location.name}! Temperatur: $lowestTemp° (Schwelle: ${threshold ?? 0.0}°)');
          
          // Formatiere die Benachrichtigungstexte
          final title = 'Frostwarnung für ${location.name}';
          final body = 'Die Temperatur sinkt auf $lowestTemp°. Bitte schützen Sie empfindliche Pflanzen!';
          
          // Sende die Benachrichtigung
          await _notificationService.showFrostWarning(title, body);
          
          // Setze den Frost-Status für diesen Standort
          _hasFrostWarning[location.id] = true;
        } else {
          debugPrint('Kein Frost für ${location.name}, Temperatur: $lowestTemp° (Schwelle: ${threshold ?? 0.0}°)');
          _hasFrostWarning[location.id] = false;
        }
      }
      
      debugPrint('Frostüberprüfung abgeschlossen');
    } catch (e) {
      debugPrint('Fehler bei der Frostüberprüfung: $e');
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
    _errorMessage = errorMessage;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
