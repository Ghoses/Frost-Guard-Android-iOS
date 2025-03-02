import 'package:flutter/material.dart';
import 'package:frost_guard/core/services/storage_service.dart';
import 'package:frost_guard/core/services/notification_service.dart';
import 'package:frost_guard/models/settings.dart';
import 'package:frost_guard/core/services/background_service.dart';

class SettingsProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  
  Settings _settings = Settings();
  
  Settings get settings => _settings;
  bool get isDarkMode => _settings.isDarkMode;
  double get temperatureThreshold => _settings.temperatureThreshold;
  bool get notificationsEnabled => _settings.notificationsEnabled;
  String get temperatureUnit => _settings.temperatureUnit;
  int get checkHour => _settings.checkHour;
  int get checkMinute => _settings.checkMinute;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _settings = await _storageService.loadSettings();
      notifyListeners();
      
      // Wenn Benachrichtigungen aktiviert sind, plane die tägliche Prüfung
      if (_settings.notificationsEnabled) {
        await _notificationService.scheduleDailyCheck(_settings.checkHour, _settings.checkMinute);
      }
    } catch (e) {
      // Fehlerbehandlung - verwende Standardeinstellungen
      _settings = Settings();
    }
  }

  Future<void> setDarkMode(bool value) async {
    _settings = _settings.copyWith(isDarkMode: value);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setTemperatureThreshold(double value) async {
    _settings = _settings.copyWith(temperatureThreshold: value);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _settings = _settings.copyWith(notificationsEnabled: value);
    notifyListeners();
    
    // Wenn Benachrichtigungen deaktiviert wurden, lösche alle geplanten Benachrichtigungen
    if (!value) {
      await _notificationService.cancelAllNotifications();
    } else {
      // Wenn aktiviert, plane die tägliche Prüfung
      await _notificationService.scheduleDailyCheck(_settings.checkHour, _settings.checkMinute);
    }
    
    await _saveSettings();
    await _updateBackgroundTask();
  }

  Future<void> setTemperatureUnit(String value) async {
    _settings = _settings.copyWith(temperatureUnit: value);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setCheckTime(int hour, int minute) async {
    try {
      debugPrint('Setze Überprüfungszeit auf $hour:$minute');
      
      // Aktualisiere Einstellungen
      _settings = _settings.copyWith(checkHour: hour, checkMinute: minute);
      notifyListeners();
      
      // Speichere Einstellungen
      await _saveSettings();
      
      // Aktualisiere den Zeitplan für Benachrichtigungen
      if (_settings.notificationsEnabled) {
        debugPrint('Benachrichtigungen sind aktiviert, aktualisiere Zeitplan');
        
        // Lösche vorherige Benachrichtigungen
        await _notificationService.cancelAllNotifications();
        
        // Plane neue Benachrichtigung
        await _notificationService.scheduleDailyCheck(hour, minute);
        
        debugPrint('Benachrichtigungen für $hour:$minute Uhr neu geplant');
      } else {
        debugPrint('Benachrichtigungen sind deaktiviert, kein Zeitplan erstellt');
      }
      
      await _updateBackgroundTask();
    } catch (e) {
      debugPrint('Fehler beim Setzen der Überprüfungszeit: $e');
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      await _storageService.saveSettings(_settings);
    } catch (e) {
      // Fehlerbehandlung bei fehlgeschlagener Speicherung
      debugPrint('Fehler beim Speichern der Einstellungen: $e');
    }
  }
  
  // Aktualisiert den Hintergrund-Task basierend auf den aktuellen Einstellungen
  Future<void> _updateBackgroundTask() async {
    try {
      // Importiere den BackgroundService dynamisch, um zirkuläre Abhängigkeiten zu vermeiden
      final BackgroundService backgroundService = BackgroundService();
      
      if (_settings.notificationsEnabled) {
        // Plane den Frost-Check
        await backgroundService.scheduleFrostCheck(_settings.checkHour, _settings.checkMinute);
        debugPrint('Frost-Check für ${_settings.checkHour}:${_settings.checkMinute} geplant');
      } else {
        // Abbrechen aller Hintergrund-Tasks
        await backgroundService.stopAllTasks();
        debugPrint('Alle Hintergrund-Tasks abgebrochen');
      }
    } catch (e) {
      debugPrint('Fehler beim Aktualisieren des Hintergrund-Tasks: $e');
    }
  }
}
