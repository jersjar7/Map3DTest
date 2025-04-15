// lib/presentation/providers/cluster_map_provider.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart'
    as cluster_manager;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/clusterable_station.dart';
import '../../domain/usecases/get_clusterable_stations.dart';
import '../../domain/usecases/get_station_count.dart';

class ClusterMapProvider extends ChangeNotifier {
  final GetClusterableStationsInRegion getClusterableStationsInRegion;
  final GetSampleClusterableStations getSampleClusterableStations;
  final GetStationCount getStationCount;

  late cluster_manager.ClusterManager<ClusterableStation> _clusterManager;
  GoogleMapController? _mapController;
  bool _isMapInitialized = false;
  bool _isLoading = false;
  bool _is3DMode = true;
  Set<Marker> _markers = {};
  double _currentZoom = AppConstants.defaultZoom;
  MapType _currentMapType = MapType.normal;
  int _totalStationCount = 0;
  LatLngBounds? _visibleRegion;
  Duration? _loadDuration;
  DateTime? _loadStartTime;
  bool _showZoomMessage = true;
  List<ClusterableStation> _items = [];

  // Getters
  GoogleMapController? get mapController => _mapController;
  bool get isMapInitialized => _isMapInitialized;
  bool get isLoading => _isLoading;
  bool get is3DMode => _is3DMode;
  Set<Marker> get markers => _markers;
  double get currentZoom => _currentZoom;
  MapType get currentMapType => _currentMapType;
  int get totalStationCount => _totalStationCount;
  LatLngBounds? get visibleRegion => _visibleRegion;
  Duration? get loadDuration => _loadDuration;
  bool get showZoomMessage => _showZoomMessage;
  int get markerCount => _markers.length;

  ClusterMapProvider({
    required this.getClusterableStationsInRegion,
    required this.getSampleClusterableStations,
    required this.getStationCount,
  }) {
    _initializeClusterManager();
  }

  void _initializeClusterManager() {
    _clusterManager = cluster_manager.ClusterManager<ClusterableStation>(
      _items,
      _updateMarkers,
      markerBuilder: _markerBuilder,
      levels: [1, 4.25, 6.75, 8.25, 11.5, 14.5, 16.0, 16.5, 20.0],
      extraPercent: 0.2,
      stopClusteringZoom: 16.0,
    );
  }

  // Initialize map controller
  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapInitialized = true;
    _clusterManager.setMapId(controller.mapId);
    notifyListeners();

    // Load sample stations for context
    _loadSampleStations();
  }

  // Handle camera movement
  void onCameraMove(CameraPosition position) {
    _currentZoom = position.zoom;
    _clusterManager.onCameraMove(position);

    // Update whether to show zoom message
    final shouldShowMessage = _currentZoom < AppConstants.minZoomForMarkers;
    if (_showZoomMessage != shouldShowMessage) {
      _showZoomMessage = shouldShowMessage;
      notifyListeners();
    }
  }

  // Handle camera idle state
  Future<void> onCameraIdle() async {
    if (_mapController == null) return;

    try {
      // Update visible region
      LatLngBounds bounds = await _mapController!.getVisibleRegion();
      _visibleRegion = bounds;

      // Load stations based on current zoom level
      if (_currentZoom >= AppConstants.minZoomForMarkers) {
        await loadStationsInVisibleRegion();
      }

      _clusterManager.updateMap();
    } catch (e) {
      debugPrint("Error updating camera: $e");
    }
  }

  void _updateMarkers(Set<Marker> markers) {
    _markers = markers;
    notifyListeners();
  }

  Future<Marker> _markerBuilder(
    cluster_manager.Cluster<ClusterableStation> cluster,
  ) async {
    // Customize the marker appearance based on whether it's a cluster or individual marker
    return Marker(
      markerId: MarkerId(cluster.getId()),
      position: cluster.location,
      onTap: () {
        // Handle marker tap
        _onMarkerTap(cluster);
      },
      icon: await _getMarkerBitmap(
        cluster.isMultiple ? 125 : 75,
        text: cluster.isMultiple ? cluster.count.toString() : null,
        isMultiple: cluster.isMultiple,
      ),
      infoWindow:
          cluster.isMultiple
              ? InfoWindow(title: '${cluster.count} stations in this area')
              : InfoWindow(
                title: 'Station ${cluster.items.first.id}',
                snippet: 'Tap for details',
              ),
    );
  }

  void _onMarkerTap(cluster_manager.Cluster<ClusterableStation> cluster) {
    // If it's a cluster with multiple items, we can add custom behavior here
    // like zooming in or showing a bottom sheet with all stations in the cluster
    if (cluster.isMultiple && _mapController != null) {
      // Option 1: Zoom in to better see the cluster contents
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(cluster.location, _currentZoom + 2.0),
      );

      // Option 2: Show a bottom sheet with all stations in this cluster
      // This would be implemented in the UI part of the app
    }
  }

  Future<BitmapDescriptor> _getMarkerBitmap(
    int size, {
    String? text,
    bool isMultiple = false,
  }) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Paint circlePaint =
        Paint()..color = isMultiple ? Colors.blue : Colors.red;

    final Paint innerCirclePaint = Paint()..color = Colors.white;

    // Draw main circle
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, circlePaint);

    // For clusters, add an inner white circle with count
    if (isMultiple) {
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2.4,
        innerCirclePaint,
      );
      canvas.drawCircle(Offset(size / 2, size / 2), size / 3.0, circlePaint);
    }

    // Add text for cluster count
    if (text != null) {
      final TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size / 3,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // Toggle 3D/2D view
  Future<void> toggleTilt() async {
    if (_mapController == null) return;

    try {
      final zoom = await _mapController!.getZoomLevel();

      // Create a new camera position with the current target
      final centerPosition =
          _visibleRegion != null
              ? LatLng(
                (_visibleRegion!.northeast.latitude +
                        _visibleRegion!.southwest.latitude) /
                    2,
                (_visibleRegion!.northeast.longitude +
                        _visibleRegion!.southwest.longitude) /
                    2,
              )
              : const LatLng(
                AppConstants.defaultLatitude,
                AppConstants.defaultLongitude,
              );

      final cameraPosition = CameraPosition(
        target: centerPosition,
        zoom: zoom,
        tilt: _is3DMode ? 0.0 : AppConstants.defaultTilt,
        bearing: 0.0,
      );

      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );

      _is3DMode = !_is3DMode;
      notifyListeners();
    } catch (e) {
      debugPrint("Error toggling tilt: $e");
    }
  }

  // Change map type
  void changeMapType(MapType mapType) {
    _currentMapType = mapType;
    notifyListeners();
  }

  // Initialize data
  Future<void> initialize() async {
    final count = await getStationCount();
    _totalStationCount = count;
    notifyListeners();
  }

  // Load sample stations for context
  Future<void> _loadSampleStations() async {
    if (!_isMapInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      final sampleStations = await getSampleClusterableStations();

      if (sampleStations.isNotEmpty) {
        _items = sampleStations;
        _clusterManager.setItems(_items);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error loading sample stations: $e");
    }
  }

  // Load stations in the currently visible region
  Future<void> loadStationsInVisibleRegion() async {
    if (!_isMapInitialized || _visibleRegion == null) return;

    _isLoading = true;
    _loadStartTime = DateTime.now();
    notifyListeners();

    try {
      final bounds = _visibleRegion!;
      final stations = await getClusterableStationsInRegion(
        bounds.southwest.latitude,
        bounds.northeast.latitude,
        bounds.southwest.longitude,
        bounds.northeast.longitude,
        limit: AppConstants.maxMarkersToShow,
      );

      if (stations.isEmpty) {
        _items = [];
        _clusterManager.setItems(_items);
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Calculate load duration
      _loadDuration = DateTime.now().difference(_loadStartTime!);

      // Update cluster manager with new items
      _items = stations;
      _clusterManager.setItems(_items);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error loading stations: $e");
    }
  }
}
