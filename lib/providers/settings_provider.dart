import 'package:flutter/material.dart';
import 'package:frost_guard/core/services/storage_service.dart';
import 'package:frost_guard/core/services/notification_service.dart';
import 'package:frost_guard/models/settings.dart';

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
  }

  Future<void> setTemperatureUnit(String value) async {
    _settings = _settings.copyWith(temperatureUnit: value);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setCheckTime(int hour, int minute) async {
    _settings = _settings.copyWith(checkHour: hour, checkMinute: minute);
    notifyListeners();
    
    // Aktualisiere den Zeitplan für Benachrichtigungen
    if (_settings.notificationsEnabled) {
      await _notificationService.cancelAllNotifications();
      await _notificationService.scheduleDailyCheck(hour, minute);
    }
    
    await _saveSettings();
  }
  
  Future<void> _saveSettings() async {
    try {
      await _storageService.saveSettings(_settings);
    } catch (e) {
      // Fehlerbehandlung bei fehlgeschlagener Speicherung
      debugPrint('Fehler beim Speichern der Einstellungen: $e');
    }
  }
}
