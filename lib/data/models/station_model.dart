// lib/data/models/station_model.dart
import '../../domain/entities/station.dart';

class StationModel extends Station {
  const StationModel({
    required super.id,
    required super.latitude,
    required super.longitude,
    super.attributes,
  });

  factory StationModel.fromMap(Map<String, dynamic> map) {
    return StationModel(
      id: map['stationId'] as int,
      latitude: map['lat'] as double,
      longitude: map['lon'] as double,
      attributes: map,
    );
  }

  Map<String, dynamic> toMap() {
    return {'stationId': id, 'lat': latitude, 'lon': longitude, ...?attributes};
  }
}
