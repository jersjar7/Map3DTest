// lib/core/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../data/datasources/local/database_helper.dart';
import '../../data/repositories/clusterable_station_repository_impl.dart';
import '../../data/repositories/station_repository_impl.dart';
import '../../domain/repositories/clusterable_station_repository.dart';
import '../../domain/repositories/station_repository.dart';
import '../../domain/usecases/get_clusterable_stations.dart';
import '../../domain/usecases/get_station_count.dart';
import '../../domain/usecases/get_stations.dart';
import '../../domain/usecases/get_stations_in_region.dart';
import '../../presentation/providers/cluster_map_provider.dart';
import '../../presentation/providers/map_provider.dart';

final GetIt sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // Data sources
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

  // Repositories
  sl.registerLazySingleton<StationRepository>(
    () => StationRepositoryImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<ClusterableStationRepository>(
    () => ClusterableStationRepositoryImpl(stationRepository: sl()),
  );

  // Use cases - Standard stations
  sl.registerLazySingleton(() => GetStationsInRegion(sl()));
  sl.registerLazySingleton(() => GetSampleStations(sl()));
  sl.registerLazySingleton(() => GetStationCount(sl()));

  // Use cases - Clusterable stations
  sl.registerLazySingleton(() => GetClusterableStationsInRegion(sl()));
  sl.registerLazySingleton(() => GetSampleClusterableStations(sl()));

  // Providers
  sl.registerFactory(
    () => MapProvider(
      getStationsInRegion: sl(),
      getSampleStations: sl(),
      getStationCount: sl(),
    ),
  );

  sl.registerFactory(
    () => ClusterMapProvider(
      getClusterableStationsInRegion: sl(),
      getSampleClusterableStations: sl(),
      getStationCount: sl(),
    ),
  );
}

// Provider list for MultiProvider
List<SingleChildWidget> getProviders() {
  return [
    ChangeNotifierProvider<MapProvider>(create: (_) => sl<MapProvider>()),
    ChangeNotifierProvider<ClusterMapProvider>(
      create: (_) => sl<ClusterMapProvider>(),
    ),
  ];
}
