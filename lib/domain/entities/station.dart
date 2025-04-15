// lib/domain/entities/station.dart
class Station {
  final int id;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? attributes;

  const Station({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.attributes,
  });
}
