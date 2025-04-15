// lib/domain/entities/clusterable_station.dart
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart'
    as cluster_manager;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'station.dart';

/// A clusterable wrapper for the Station entity
class ClusterableStation with cluster_manager.ClusterItem {
  final Station station;

  ClusterableStation({required this.station});

  @override
  LatLng get location => LatLng(station.latitude, station.longitude);

  /// Creates a clusterable station from a normal station entity
  factory ClusterableStation.fromStation(Station station) {
    return ClusterableStation(station: station);
  }

  /// Gets the station ID
  int get id => station.id;

  /// Gets the station attributes, if any
  Map<String, dynamic>? get attributes => station.attributes;

  @override
  String toString() =>
      'ClusterableStation(id: ${station.id}, lat: ${station.latitude}, lon: ${station.longitude})';
}
