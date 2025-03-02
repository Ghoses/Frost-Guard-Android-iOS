import 'package:uuid/uuid.dart';

class Location {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final bool isCurrentLocation;

  Location({
    String? id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isCurrentLocation = false,
  }) : id = id ?? const Uuid().v4();

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      isCurrentLocation: json['isCurrentLocation'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'isCurrentLocation': isCurrentLocation,
    };
  }
  
  // Erstellt eine Kopie des Location-Objekts mit aktualisierten Feldern
  Location copyWith({
    String? name,
    double? latitude,
    double? longitude,
    bool? isCurrentLocation,
  }) {
    return Location(
      id: id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isCurrentLocation: isCurrentLocation ?? this.isCurrentLocation,
    );
  }
}
