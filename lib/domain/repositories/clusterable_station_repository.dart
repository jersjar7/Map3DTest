// lib/domain/repositories/clusterable_station_repository.dart
import '../entities/clusterable_station.dart';

abstract class ClusterableStationRepository {
  /// Get a sample of clusterable stations for initial view
  Future<List<ClusterableStation>> getSampleClusterableStations({int limit});

  /// Get clusterable stations within a specific geographic region
  Future<List<ClusterableStation>> getClusterableStationsInRegion(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon, {
    int limit,
  });

  /// Get the total number of stations in the database
  Future<int> getStationCount();
}
