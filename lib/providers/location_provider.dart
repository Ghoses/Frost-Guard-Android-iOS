import 'package:flutter/material.dart';
import 'package:frost_guard/core/services/storage_service.dart';
import 'package:frost_guard/core/services/location_service.dart';
import 'package:frost_guard/models/location.dart';

class LocationProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();
  
  List<Location> _locations = [];
  bool _isLoading = false;
  String _error = '';
  
  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  // Standorte aus dem lokalen Speicher laden
  Future<void> loadLocations() async {
    _setLoading(true);
    _clearError();
    
    try {
      _locations = await _storageService.loadLocations();
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Laden der Standorte: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Aktuellen Standort hinzufügen
  Future<Location?> addCurrentLocation() async {
    _setLoading(true);
    _clearError();
    
    try {
      final currentLocation = await _locationService.getCurrentLocation();
      
      // Prüfe, ob bereits ein aktueller Standort vorhanden ist
      final index = _locations.indexWhere((loc) => loc.isCurrentLocation);
      
      if (index >= 0) {
        // Aktualisiere den bestehenden Standort
        _locations[index] = currentLocation;
      } else {
        // Füge den neuen Standort hinzu
        _locations.add(currentLocation);
      }
      
      await _storageService.saveLocations(_locations);
      notifyListeners();
      return currentLocation;
    } catch (e) {
      _setError('Fehler beim Hinzufügen des aktuellen Standorts: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Standort hinzufügen
  Future<Location?> addLocation(Location location) async {
    // Prüfe, ob Standort bereits vorhanden ist
    if (_locations.any((loc) => 
        loc.latitude == location.latitude && 
        loc.longitude == location.longitude)) {
      _setError('Dieser Standort ist bereits in Ihrer Liste vorhanden.');
      return null;
    }
    
    _clearError();
    _locations.add(location);
    notifyListeners();
    
    try {
      await _storageService.saveLocations(_locations);
      return location;
    } catch (e) {
      _setError('Fehler beim Speichern des Standorts: $e');
      _locations.removeLast();
      notifyListeners();
      return null;
    }
  }
  
  // Standort entfernen
  Future<void> removeLocation(String id) async {
    final index = _locations.indexWhere((loc) => loc.id == id);
    
    if (index < 0) {
      return;
    }
    
    final deletedLocation = _locations[index];
    _locations.removeAt(index);
    notifyListeners();
    
    try {
      await _storageService.saveLocations(_locations);
    } catch (e) {
      _setError('Fehler beim Entfernen des Standorts: $e');
      _locations.insert(index, deletedLocation);
      notifyListeners();
    }
  }
  
  // Standorte nach Namen suchen
  Future<List<Location>> searchLocations(String query) async {
    if (query.isEmpty) {
      return [];
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      final results = await _locationService.searchLocationsByName(query);
      _setLoading(false);
      return results;
    } catch (e) {
      _setError('Fehler bei der Standortsuche: $e');
      _setLoading(false);
      return [];
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
