import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frost_guard/core/constants/app_constants.dart';
import 'package:frost_guard/core/errors/exceptions.dart';
import 'package:frost_guard/models/location.dart';
import 'package:frost_guard/models/settings.dart';

class StorageService {
  // Einstellungen laden
  Future<Settings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final isDarkMode = prefs.getBool(AppConstants.KEY_DARK_MODE);
      final tempThreshold = prefs.getDouble(AppConstants.KEY_TEMPERATURE_THRESHOLD);
      final notificationsEnabled = prefs.getBool(AppConstants.KEY_NOTIFICATIONS_ENABLED);
      final tempUnit = prefs.getString(AppConstants.KEY_TEMPERATURE_UNIT);
      final checkHour = prefs.getInt(AppConstants.KEY_CHECK_HOUR);
      final checkMinute = prefs.getInt(AppConstants.KEY_CHECK_MINUTE);
      
      return Settings(
        isDarkMode: isDarkMode ?? AppConstants.DEFAULT_DARK_MODE,
        temperatureThreshold: tempThreshold ?? AppConstants.DEFAULT_TEMPERATURE_THRESHOLD,
        notificationsEnabled: notificationsEnabled ?? AppConstants.DEFAULT_NOTIFICATIONS_ENABLED,
        temperatureUnit: tempUnit ?? AppConstants.DEFAULT_TEMPERATURE_UNIT,
        checkHour: checkHour ?? AppConstants.DEFAULT_CHECK_HOUR,
        checkMinute: checkMinute ?? AppConstants.DEFAULT_CHECK_MINUTE,
      );
    } catch (e) {
      throw StorageException('Fehler beim Laden der Einstellungen: $e');
    }
  }
  
  // Einstellungen speichern
  Future<void> saveSettings(Settings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(AppConstants.KEY_DARK_MODE, settings.isDarkMode);
      await prefs.setDouble(AppConstants.KEY_TEMPERATURE_THRESHOLD, settings.temperatureThreshold);
      await prefs.setBool(AppConstants.KEY_NOTIFICATIONS_ENABLED, settings.notificationsEnabled);
      await prefs.setString(AppConstants.KEY_TEMPERATURE_UNIT, settings.temperatureUnit);
      await prefs.setInt(AppConstants.KEY_CHECK_HOUR, settings.checkHour);
      await prefs.setInt(AppConstants.KEY_CHECK_MINUTE, settings.checkMinute);
    } catch (e) {
      throw StorageException('Fehler beim Speichern der Einstellungen: $e');
    }
  }
  
  // Standorte laden
  Future<List<Location>> loadLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getStringList(AppConstants.KEY_LOCATIONS);
      
      if (locationsJson == null || locationsJson.isEmpty) {
        return [];
      }
      
      return locationsJson
        .map((json) => Location.fromJson(jsonDecode(json)))
        .toList();
    } catch (e) {
      throw StorageException('Fehler beim Laden der Standorte: $e');
    }
  }
  
  // Standorte speichern
  Future<void> saveLocations(List<Location> locations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final locationsJson = locations
        .map((location) => jsonEncode(location.toJson()))
        .toList();
      
      await prefs.setStringList(AppConstants.KEY_LOCATIONS, locationsJson);
    } catch (e) {
      throw StorageException('Fehler beim Speichern der Standorte: $e');
    }
  }
}
