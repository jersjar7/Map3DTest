// lib/domain/repositories/station_repository.dart
import '../entities/station.dart';

abstract class StationRepository {
  /// Get a sample of stations (e.g., for low zoom levels)
  Future<List<Station>> getSampleStations({int limit});

  /// Get stations within a specific geographic region
  Future<List<Station>> getStationsInRegion(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon, {
    int limit,
  });

  /// Get the total number of stations in the database
  Future<int> getStationCount();
}
