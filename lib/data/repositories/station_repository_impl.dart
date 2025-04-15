// lib/data/repositories/station_repository_impl.dart
import '../../domain/entities/station.dart';
import '../../domain/repositories/station_repository.dart';
import '../datasources/local/database_helper.dart';
import '../models/station_model.dart';

class StationRepositoryImpl implements StationRepository {
  final DatabaseHelper databaseHelper;

  StationRepositoryImpl({required this.databaseHelper});

  @override
  Future<List<Station>> getSampleStations({int limit = 10}) async {
    final stationMaps = await databaseHelper.getSampleStations(limit: limit);
    return stationMaps.map((map) => StationModel.fromMap(map)).toList();
  }

  @override
  Future<List<Station>> getStationsInRegion(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon, {
    int limit = 1000,
  }) async {
    final stationMaps = await databaseHelper.getStationsInRegion(
      minLat,
      maxLat,
      minLon,
      maxLon,
      limit: limit,
    );

    return stationMaps.map((map) => StationModel.fromMap(map)).toList();
  }

  @override
  Future<int> getStationCount() async {
    return databaseHelper.getStationCount();
  }
}
