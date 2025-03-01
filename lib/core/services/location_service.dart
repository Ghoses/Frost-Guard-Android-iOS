import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:http/http.dart' as http;
import 'package:frost_guard/core/constants/api_constants.dart';
import 'package:frost_guard/core/errors/exceptions.dart';
import 'package:frost_guard/models/location.dart';

class LocationService {
  final String apiKey = dotenv.env['OPENWEATHERMAP_API_KEY'] ?? '';
  
  // Aktuellen Standort ermitteln
  Future<Location> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Prüfen, ob Standortdienste aktiviert sind
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException('Standortdienste sind nicht aktiviert.');
      }

      // Standortberechtigung prüfen
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationException('Standortberechtigungen verweigert.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw LocationException(
          'Standortberechtigungen dauerhaft verweigert. '
          'Bitte in den Einstellungen aktivieren.'
        );
      }

      // Aktuellen Standort abrufen
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      
      // Versuche, den Ortsnamen zu ermitteln
      String locationName = 'Aktueller Standort';
      try {
        final places = await geocoding.placemarkFromCoordinates(
          position.latitude, 
          position.longitude,
          localeIdentifier: 'de',
        );
        
        // Ortsnamen zusammensetzen
        if (places.isNotEmpty) {
          final place = places.first;
          if (place.locality != null && place.locality!.isNotEmpty) {
            locationName = place.locality!;
          } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            locationName = place.administrativeArea!;
          }
        }
      } catch (e) {
        debugPrint('Fehler beim Ermitteln des Ortsnamens: $e');
        // Verwende den Standardnamen weiter, wenn die Geocoding-API fehlschlägt
      }
      
      return Location(
        name: locationName,
        latitude: position.latitude,
        longitude: position.longitude,
        isCurrentLocation: true,
      );
    } catch (e) {
      debugPrint('Fehler beim Ermitteln des Standorts: $e');
      throw LocationException('Fehler beim Ermitteln des Standorts: $e');
    }
  }
  
  // Standorte nach Name suchen
  Future<List<Location>> searchLocationsByName(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    try {
      final response = await http.get(Uri.parse(
        '${ApiConstants.GEOCODING_BASE_URL}${ApiConstants.GEOCODING_ENDPOINT}?${ApiConstants.PARAM_QUERY}=$query&${ApiConstants.PARAM_LIMIT}=${ApiConstants.DEFAULT_LOCATION_LIMIT}&${ApiConstants.PARAM_APP_ID}=$apiKey'
      ));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Location(
          name: '${item['name']}, ${item['country']}',
          latitude: item['lat'],
          longitude: item['lon'],
        )).toList();
      } else {
        throw LocationException(
          'Fehler bei der Standortsuche: ${response.statusCode}'
        );
      }
    } catch (e) {
      throw LocationException('Netzwerkfehler: $e');
    }
  }
}
