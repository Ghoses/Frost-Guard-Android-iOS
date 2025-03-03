import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:frost_guard/core/services/notification_service.dart';
import 'package:frost_guard/core/services/weather_service.dart';
import 'package:frost_guard/models/location.dart';
import 'package:frost_guard/models/weather_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frost_guard/core/constants/app_constants.dart';
import 'package:frost_guard/core/services/location_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  final WeatherService _weatherService = WeatherService();
  final NotificationService _notificationService = NotificationService();
  final LocationService _locationService = LocationService();
  
  bool _isRunning = false;
  
  factory BackgroundService() {
    return _instance;
  }
  
  BackgroundService._internal();

  // Speichere einen Standort
  Future<void> saveLocation(Location location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Hole bestehende Standorte
      final locationData = prefs.getStringList(AppConstants.KEY_LOCATIONS) ?? [];
      
      // Konvertiere Standort zu JSON
      final locationJson = jsonEncode(location.toJson());
      
      // Prüfe, ob Standort bereits existiert
      final existingIndex = locationData.indexWhere((json) {
        final Map<String, dynamic> existingLocation = jsonDecode(json);
        return existingLocation['latitude'] == location.latitude && 
               existingLocation['longitude'] == location.longitude;
      });
      
      if (existingIndex != -1) {
        // Aktualisiere existierenden Standort
        locationData[existingIndex] = locationJson;
      } else {
        // Füge neuen Standort hinzu
        locationData.add(locationJson);
      }
      
      // Speichere aktualisierte Standortliste
      await prefs.setStringList(AppConstants.KEY_LOCATIONS, locationData);
      
      debugPrint('Standort gespeichert: ${location.name}');
    } catch (e) {
      debugPrint('Fehler beim Speichern des Standorts: $e');
    }
  }

  // Lade den aktuellen Standort
  Future<Location?> loadCurrentLocation() async {
    try {
      // Versuche, den aktuellen Standort zu laden
      final currentLocation = await _locationService.getCurrentLocation();
      
      // Speichere den aktuellen Standort
      await saveLocation(currentLocation);
      
      return currentLocation;
    } catch (e) {
      debugPrint('Fehler beim Laden des aktuellen Standorts: $e');
      return null;
    }
  }

  // Initialisiere Standorte für Hintergrundaufgaben
  Future<void> initializeLocationsForBackgroundTasks() async {
    try {
      // Versuche, den aktuellen Standort zu laden und zu speichern
      await loadCurrentLocation();
      
      debugPrint('Standorte für Hintergrundaufgaben initialisiert');
    } catch (e) {
      debugPrint('Fehler bei der Initialisierung der Standorte: $e');
    }
  }

  // Initialisiert den Hintergrund-Service
  Future<void> init() async {
    debugPrint('Initialisiere BackgroundService');
    
    try {
      // Initialisiere Standorte vor der Konfiguration von BackgroundFetch
      await initializeLocationsForBackgroundTasks();
      
      // Konfiguriere BackgroundFetch
      await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15, // Mindestintervall in Minuten (wird später überschrieben)
          stopOnTerminate: false,
          enableHeadless: true,
          startOnBoot: true,
          forceAlarmManager: true,
          requiredNetworkType: NetworkType.ANY,
        ),
        _onBackgroundFetch,
        _onBackgroundFetchTimeout,
      );
      
      // Lade gespeicherte Einstellungen
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      
      if (notificationsEnabled) {
        final hour = prefs.getInt('check_hour') ?? 7;
        final minute = prefs.getInt('check_minute') ?? 0;
        
        // Plane den Frost-Check
        await scheduleFrostCheck(hour, minute);
      } else {
        // Stoppe den Hintergrund-Service, wenn Benachrichtigungen deaktiviert sind
        await stopAllTasks();
      }
      
      debugPrint('BackgroundService erfolgreich initialisiert');
    } catch (e) {
      debugPrint('Fehler bei der Initialisierung des BackgroundService: $e');
      rethrow;
    }
  }
  
  // Callback für BackgroundFetch
  void _onBackgroundFetch(String taskId) async {
    debugPrint('[BackgroundFetch] Task ID: $taskId');
    
    // Führe den Frost-Check durch
    await performFrostCheck();
    
    // Markiere den Task als abgeschlossen
    BackgroundFetch.finish(taskId);
  }
  
  // Callback für BackgroundFetch Timeout
  void _onBackgroundFetchTimeout(String taskId) {
    debugPrint('[BackgroundFetch] TIMEOUT: $taskId');
    BackgroundFetch.finish(taskId);
  }
  
  // Plant eine tägliche Überprüfung auf Frost
  Future<void> scheduleFrostCheck(int hour, int minute) async {
    debugPrint('Plane Frost-Check für $hour:$minute Uhr');
    
    try {
      // Stoppe zuerst alle vorherigen Tasks
      await stopAllTasks();
      
      // Berechne die nächste Ausführungszeit
      final now = DateTime.now();
      var scheduledTime = DateTime(
        now.year, 
        now.month, 
        now.day, 
        hour, 
        minute
      );
      
      // Wenn die Zeit für heute bereits vorbei ist, auf morgen setzen
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      
      // Berechne die Verzögerung bis zur nächsten Ausführung
      final initialDelay = scheduledTime.difference(now);
      
      debugPrint('Nächste geplante Ausführung: ${scheduledTime.toString()}');
      debugPrint('Verzögerung zur ersten Ausführung: ${initialDelay.inHours} Stunden und ${initialDelay.inMinutes % 60} Minuten');
      
      // Speichere die geplante Zeit in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('check_hour', hour);
      await prefs.setInt('check_minute', minute);
      
      // Aktiviere BackgroundFetch, falls es deaktiviert ist
      await BackgroundFetch.start();
      
      // Konfiguriere einen einmaligen Task für die erste Ausführung
      await BackgroundFetch.scheduleTask(TaskConfig(
        taskId: 'frost_check_initial',
        delay: initialDelay.inMilliseconds,
        periodic: false,
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresNetworkConnectivity: true,
        requiresCharging: false,
        requiresBatteryNotLow: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false
      ));
      
      // Konfiguriere einen täglichen Task (24 Stunden)
      final oneDayInMillis = const Duration(days: 1).inMilliseconds;
      await BackgroundFetch.scheduleTask(TaskConfig(
        taskId: 'frost_check_main',
        delay: initialDelay.inMilliseconds + oneDayInMillis,
        periodic: true,
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresNetworkConnectivity: true,
        requiresCharging: false,
        requiresBatteryNotLow: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false
      ));
      
      debugPrint('Frost-Check erfolgreich geplant');
      return;
    } catch (e) {
      debugPrint('Fehler beim Planen des Frost-Checks: $e');
      rethrow;
    }
  }
  
  // Führt eine sofortige Überprüfung auf Frost durch
  Future<void> checkForFrostNow() async {
    debugPrint('Starte sofortige Frost-Überprüfung');
    
    try {
      // Führe den Callback direkt aus
      await performFrostCheck();
      debugPrint('Sofortige Frost-Überprüfung abgeschlossen');
    } catch (e) {
      debugPrint('Fehler bei sofortiger Frost-Überprüfung: $e');
      rethrow;
    }
  }
  
  // Führt die eigentliche Frost-Überprüfung durch
  Future<void> performFrostCheck() async {
    // Verhindere mehrfache gleichzeitige Ausführungen
    if (_isRunning) {
      debugPrint('Frost-Check läuft bereits, überspringe');
      return;
    }
    
    _isRunning = true;
    
    try {
      debugPrint('Frost-Check-Callback ausgelöst');
      
      // Lade gespeicherte Standorte
      final prefs = await SharedPreferences.getInstance();
      final locationData = prefs.getStringList(AppConstants.KEY_LOCATIONS) ?? [];
      
      if (locationData.isEmpty) {
        debugPrint('Keine Standorte gefunden, überspringe Frost-Check');
        return;
      }
      
      // Lade Schwellenwert aus Einstellungen
      final threshold = prefs.getDouble(AppConstants.KEY_TEMPERATURE_THRESHOLD) ?? 3.0;
      debugPrint('Frostschwellenwert: $threshold°');
      
      // Liste für Frost-Warnungen
      final frostWarnings = <Map<String, String>>[];
      
      // Überprüfe jeden Standort auf Frost
      for (final locationJson in locationData) {
        try {
          // Konvertiere den String in eine Map und dann in ein Location-Objekt
          final Map<String, dynamic> locationMap = json.decode(locationJson);
          final location = Location.fromJson(locationMap);
          debugPrint('Überprüfe Standort: ${location.name}');
          
          // Hole Wetterdaten für diesen Standort
          final weatherData = await _weatherService.getForecast(location.latitude, location.longitude);
          
          if (weatherData == null) {
            debugPrint('Keine Wetterdaten für ${location.name} verfügbar, überspringe');
            continue;
          }
          
          // Ermittle die niedrigste Temperatur
          final lowestTemp = _getLowestTemperatureFromData(weatherData);
          
          debugPrint('Niedrigste Temperatur für ${location.name}: $lowestTemp°, Schwellenwert: $threshold°');
          
          // Ist die Temperatur unter dem Schwellenwert?
          if (lowestTemp <= threshold) {
            debugPrint('Frost erkannt für ${location.name}! Temperatur: $lowestTemp° (Schwelle: $threshold°)');
            
            // Formatiere die Benachrichtigungstexte
            final title = 'Frostwarnung für ${location.name}';
            final body = 'Die Temperatur sinkt auf $lowestTemp°. Bitte schützen Sie empfindliche Pflanzen!';
            
            // Füge Warnung zur Liste hinzu
            frostWarnings.add({
              'title': title,
              'body': body,
            });
            
            // Speichere Frost-Status
            await prefs.setBool('frost_warning_${location.id}', true);
          } else {
            debugPrint('Kein Frost für ${location.name}, Temperatur: $lowestTemp° (Schwelle: $threshold°)');
            await prefs.setBool('frost_warning_${location.id}', false);
          }
        } catch (e) {
          debugPrint('Fehler bei der Überprüfung von Standort: $e');
          continue;
        }
      }
      
      // Sende Benachrichtigungen mit Verzögerung
      for (final warning in frostWarnings) {
        await _notificationService.showFrostWarning(warning['title']!, warning['body']!);
        
        // Warte 3 Sekunden zwischen den Benachrichtigungen
        await Future.delayed(const Duration(seconds: 3));
      }
      
      debugPrint('Frost-Check abgeschlossen');
    } catch (e) {
      debugPrint('Fehler beim Frost-Check: $e');
    } finally {
      _isRunning = false;
    }
  }
  
  // Ermittelt die niedrigste Temperatur aus den Wetterdaten
  double _getLowestTemperatureFromData(WeatherData weatherData) {
    double lowestTemp = 100.0; // Hoher Startwert
    
    // Prüfe stündliche Daten
    for (final hourData in weatherData.hourly) {
      if (hourData.temp < lowestTemp) {
        lowestTemp = hourData.temp;
      }
    }
    
    // Prüfe tägliche Daten
    for (final dayData in weatherData.daily) {
      if (dayData.temp.min < lowestTemp) {
        lowestTemp = dayData.temp.min;
      }
    }
    
    return lowestTemp;
  }
  
  // Stoppt alle geplanten Hintergrundaufgaben
  Future<void> stopAllTasks() async {
    debugPrint('Stoppe alle Hintergrundaufgaben');
    
    try {
      // Stoppe alle BackgroundFetch-Tasks
      await BackgroundFetch.stop();
      debugPrint('Alle Hintergrundaufgaben gestoppt');
    } catch (e) {
      debugPrint('Fehler beim Stoppen der Hintergrundaufgaben: $e');
      rethrow;
    }
  }
}
