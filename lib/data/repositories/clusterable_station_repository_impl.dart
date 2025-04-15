// lib/data/repositories/clusterable_station_repository_impl.dart
import '../../domain/entities/clusterable_station.dart';
import '../../domain/repositories/clusterable_station_repository.dart';
import '../../domain/repositories/station_repository.dart';

class ClusterableStationRepositoryImpl implements ClusterableStationRepository {
  final StationRepository stationRepository;

  ClusterableStationRepositoryImpl({required this.stationRepository});

  @override
  Future<List<ClusterableStation>> getSampleClusterableStations({
    int limit = 10,
  }) async {
    final stations = await stationRepository.getSampleStations(limit: limit);
    return stations
        .map((station) => ClusterableStation.fromStation(station))
        .toList();
  }

  @override
  Future<List<ClusterableStation>> getClusterableStationsInRegion(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon, {
    int limit = 1000,
  }) async {
    final stations = await stationRepository.getStationsInRegion(
      minLat,
      maxLat,
      minLon,
      maxLon,
      limit: limit,
    );

    return stations
        .map((station) => ClusterableStation.fromStation(station))
        .toList();
  }

  @override
  Future<int> getStationCount() async {
    return stationRepository.getStationCount();
  }
}
