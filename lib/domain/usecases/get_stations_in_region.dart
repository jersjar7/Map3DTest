// lib/domain/usecases/get_stations_in_region.dart
import '../entities/station.dart';
import '../repositories/station_repository.dart';

class GetStationsInRegion {
  final StationRepository repository;

  const GetStationsInRegion(this.repository);

  Future<List<Station>> call(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon, {
    int limit = 1000,
  }) async {
    return repository.getStationsInRegion(
      minLat,
      maxLat,
      minLon,
      maxLon,
      limit: limit,
    );
  }
}
