// lib/domain/usecases/get_stations.dart
import '../entities/station.dart';
import '../repositories/station_repository.dart';

class GetSampleStations {
  final StationRepository repository;

  const GetSampleStations(this.repository);

  Future<List<Station>> call({int limit = 10}) async {
    return repository.getSampleStations(limit: limit);
  }
}
