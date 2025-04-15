// lib/domain/usecases/get_clusterable_stations.dart
import '../entities/clusterable_station.dart';
import '../repositories/clusterable_station_repository.dart';

class GetSampleClusterableStations {
  final ClusterableStationRepository repository;

  const GetSampleClusterableStations(this.repository);

  Future<List<ClusterableStation>> call({int limit = 10}) async {
    return repository.getSampleClusterableStations(limit: limit);
  }
}

class GetClusterableStationsInRegion {
  final ClusterableStationRepository repository;

  const GetClusterableStationsInRegion(this.repository);

  Future<List<ClusterableStation>> call(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon, {
    int limit = 1000,
  }) async {
    return repository.getClusterableStationsInRegion(
      minLat,
      maxLat,
      minLon,
      maxLon,
      limit: limit,
    );
  }
}
