// lib/domain/usecases/get_station_count.dart
import '../repositories/station_repository.dart';

class GetStationCount {
  final StationRepository repository;

  const GetStationCount(this.repository);

  Future<int> call() async {
    return repository.getStationCount();
  }
}
