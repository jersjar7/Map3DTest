// lib/presentation/providers/map_provider.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/station.dart';
import '../../domain/usecases/get_station_count.dart';
import '../../domain/usecases/get_stations.dart';
import '../../domain/usecases/get_stations_in_region.dart';

class MapProvider extends ChangeNotifier {
  final GetStationsInRegion getStationsInRegion;
  final GetSampleStations getSampleStations;
  final GetStationCount getStationCount;

  GoogleMapController? _mapController;
  bool _isMapInitialized = false;
  bool _isLoading = false;
  bool _is3DMode = true;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  double _currentZoom = AppConstants.defaultZoom;
  MapType _currentMapType = MapType.normal;
  int _markerCount = 0;
  int _totalStationCount = 0;
  LatLngBounds? _visibleRegion;
  Duration? _loadDuration;
  DateTime? _loadStartTime;
  bool _showZoomMessage = true;

  // Getters
  GoogleMapController? get mapController => _mapController;
  bool get isMapInitialized => _isMapInitialized;
  bool get isLoading => _isLoading;
  bool get is3DMode => _is3DMode;
  Set<Marker> get markers => _markers;
  Set<Circle> get circles => _circles;
  double get currentZoom => _currentZoom;
  MapType get currentMapType => _currentMapType;
  int get markerCount => _markerCount;
  int get totalStationCount => _totalStationCount;
  LatLngBounds? get visibleRegion => _visibleRegion;
  Duration? get loadDuration => _loadDuration;
  bool get showZoomMessage => _showZoomMessage;

  MapProvider({
    required this.getStationsInRegion,
    required this.getSampleStations,
    required this.getStationCount,
  });

  // Initialize map controller
  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapInitialized = true;
    notifyListeners();

    // Load sample stations for context at low zoom
    _loadSampleStations();
  }

  // Handle camera movement
  void onCameraMove(CameraPosition position) {
    _currentZoom = position.zoom;

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

      // Only load stations if we're zoomed in enough
      if (_currentZoom >= AppConstants.minZoomForMarkers) {
        await loadStationsInVisibleRegion();
      } else if (_markers.isNotEmpty) {
        // Clear markers when zoomed out for performance
        _markers = {};
        _circles = {};
        _markerCount = 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error updating camera: $e");
    }
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

  // Load sample stations for context when zoomed out
  Future<void> _loadSampleStations() async {
    if (!_isMapInitialized) return;

    try {
      final sampleStations = await getSampleStations();

      if (sampleStations.isNotEmpty) {
        final Set<Marker> newMarkers = {};

        for (var station in sampleStations) {
          // Add a marker
          final marker = Marker(
            markerId: MarkerId(station.id.toString()),
            position: LatLng(station.latitude, station.longitude),
            infoWindow: InfoWindow(
              title: 'Station ${station.id}',
              snippet: 'Sample Station',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          );
          newMarkers.add(marker);
        }

        _markers = newMarkers;
        notifyListeners();
      }
    } catch (e) {
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
      final stations = await getStationsInRegion(
        bounds.southwest.latitude,
        bounds.northeast.latitude,
        bounds.southwest.longitude,
        bounds.northeast.longitude,
        limit: AppConstants.maxMarkersToShow,
      );

      if (stations.isEmpty) {
        _markers = {};
        _circles = {};
        _markerCount = 0;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final newMarkers = <Marker>{};
      final newCircles = <Circle>{};

      // Add markers for stations
      for (var station in stations) {
        final color = _getColorForStation(station);

        // Add a circle for the base
        final circle = Circle(
          circleId: CircleId('circle_${station.id}'),
          center: LatLng(station.latitude, station.longitude),
          radius: 500, // Radius in meters
          fillColor: _parseColor(color).withOpacity(0.5),
          strokeColor: Colors.white,
          strokeWidth: 1,
        );
        newCircles.add(circle);

        // Add a marker
        final marker = Marker(
          markerId: MarkerId(station.id.toString()),
          position: LatLng(station.latitude, station.longitude),
          infoWindow: InfoWindow(
            title: 'Station ${station.id}',
            snippet: 'Lat: ${station.latitude}, Lng: ${station.longitude}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(_getHueFromColor(color)),
        );
        newMarkers.add(marker);
      }

      // Calculate load duration
      _loadDuration = DateTime.now().difference(_loadStartTime!);

      _markers = newMarkers;
      _circles = newCircles;
      _markerCount = stations.length;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error loading stations: $e");
    }
  }

  // Helper methods for marker styling
  Color _parseColor(String colorString) {
    String hexColor = colorString.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  double _getHueFromColor(String colorString) {
    switch (colorString.toLowerCase()) {
      case '#2389da':
        return BitmapDescriptor.hueAzure;
      case '#0074d9':
        return BitmapDescriptor.hueBlue;
      case '#0052cc':
        return BitmapDescriptor.hueBlue;
      case '#004080':
        return BitmapDescriptor.hueCyan;
      case '#001f3f':
        return BitmapDescriptor.hueBlue;
      default:
        return BitmapDescriptor.hueBlue;
    }
  }

  String _getColorForStation(Station station) {
    final List<String> colors = [
      '#2389da', // Light blue
      '#0074d9', // Blue
      '#0052cc', // Medium blue
      '#004080', // Dark blue
      '#001f3f', // Navy
    ];

    final colorIndex = station.id % colors.length;
    return colors[colorIndex];
  }
}
