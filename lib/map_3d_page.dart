// In lib/map_3d_page.dart, update your existing code:

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'database_helper.dart';
import 'mapbox_page.dart'; // Add this import for the MapBox page

class Map3DPage extends StatefulWidget {
  const Map3DPage({super.key});

  @override
  State<Map3DPage> createState() => _Map3DPageState();
}

class _Map3DPageState extends State<Map3DPage> {
  GoogleMapController? _mapController;
  bool _isMapInitialized = false;
  bool _isLoading = false;
  int _markerCount = 0;
  int _totalStationCount = 0;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Performance tracking variables
  DateTime? _loadStartTime;
  Duration? _loadDuration;

  // Default center of the map (USA center)
  final LatLng _center = const LatLng(40.233845, -111.658531);

  // Map markers and features
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  // Map type toggle
  MapType _currentMapType = MapType.normal;

  // 3D mode state
  bool _is3DMode = true;

  // Zoom level threshold for showing markers
  // This is a critical value for performance with 1M+ markers
  static const double _minZoomForMarkers = 12.0;
  double _currentZoom = 10.0;

  // Current visible region
  LatLngBounds? _visibleRegion;

  // Whether we're showing "zoom in" message
  bool _showZoomMessage = true;

  @override
  void initState() {
    super.initState();
    // Fetch total count for info display
    _fetchTotalCount();
  }

  Future<void> _fetchTotalCount() async {
    final count = await _databaseHelper.getStationCount();
    setState(() {
      _totalStationCount = count;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapInitialized = true;
    });

    // Initial camera position
    _updateVisibleRegion();

    // Load some sample stations for context at low zoom
    _loadSampleStations();
  }

  void _onCameraMove(CameraPosition position) {
    _currentZoom = position.zoom;

    // Update whether to show zoom message
    final shouldShowMessage = _currentZoom < _minZoomForMarkers;
    if (_showZoomMessage != shouldShowMessage) {
      setState(() {
        _showZoomMessage = shouldShowMessage;
      });
    }
  }

  void _onCameraIdle() {
    _updateVisibleRegion();

    // Only load stations if we're zoomed in enough
    if (_currentZoom >= _minZoomForMarkers) {
      _loadStationsInVisibleRegion();
    } else if (_markers.isNotEmpty) {
      // Clear markers when zoomed out for performance
      setState(() {
        _markers.clear();
        _circles.clear();
        _markerCount = 0;
      });
    }
  }

  Future<void> _updateVisibleRegion() async {
    if (_mapController == null) return;

    try {
      LatLngBounds bounds = await _mapController!.getVisibleRegion();
      _visibleRegion = bounds;
    } catch (e) {
      print("Error getting visible region: $e");
    }
  }

  // Load a small sample of stations when zoomed out
  Future<void> _loadSampleStations() async {
    if (!_isMapInitialized) return;

    final sampleStations = await _databaseHelper.getSampleStations(limit: 10);

    // Add few sample markers for reference
    if (sampleStations.isNotEmpty) {
      setState(() {
        _markers.clear();
        _circles.clear();

        for (var station in sampleStations) {
          final lat = station['lat'] as double?;
          final lon = station['lon'] as double?;
          final id = station['stationId'];

          if (lat == null || lon == null || id == null) continue;

          // Add a marker
          final marker = Marker(
            markerId: MarkerId(id.toString()),
            position: LatLng(lat, lon),
            infoWindow: InfoWindow(
              title: 'Station $id',
              snippet: 'Sample Station',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          );
          _markers.add(marker);
        }
      });
    }
  }

  // Load stations in the currently visible region
  Future<void> _loadStationsInVisibleRegion() async {
    if (!_isMapInitialized || _visibleRegion == null) return;

    setState(() {
      _isLoading = true;
      _loadStartTime = DateTime.now();
    });

    try {
      final bounds = _visibleRegion!;
      final stations = await _databaseHelper.getStationsInRegion(
        bounds.southwest.latitude,
        bounds.northeast.latitude,
        bounds.southwest.longitude,
        bounds.northeast.longitude,
        limit: 1000, // Limit to prevent performance issues
      );

      if (stations.isEmpty) {
        print("No stations found in visible region");
        setState(() {
          _markers.clear();
          _circles.clear();
          _markerCount = 0;
          _isLoading = false;
        });
        return;
      }

      print("Loaded ${stations.length} stations in visible region");

      // Add markers for stations
      await _addMarkers(stations);

      // Calculate load duration
      _loadDuration = DateTime.now().difference(_loadStartTime!);
      print("Stations loaded in: ${_loadDuration!.inMilliseconds}ms");

      setState(() {
        _markerCount = stations.length;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading stations: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add markers for stations
  Future<void> _addMarkers(List<Map<String, dynamic>> stations) async {
    if (_mapController == null) return;

    // Clear existing markers and circles
    _markers.clear();
    _circles.clear();

    for (var station in stations) {
      final lat = station['lat'] as double?;
      final lon = station['lon'] as double?;
      final id = station['stationId'];

      if (lat == null || lon == null || id == null) continue;

      final color = _getColorForStation(station);

      // Add a circle for the base (smaller for large datasets)
      final circle = Circle(
        circleId: CircleId('circle_$id'),
        center: LatLng(lat, lon),
        radius: 500, // Radius in meters - smaller for dense markers
        fillColor: _parseColor(color).withOpacity(0.5),
        strokeColor: Colors.white,
        strokeWidth: 1,
      );
      _circles.add(circle);

      // Add a marker
      final marker = Marker(
        markerId: MarkerId(id.toString()),
        position: LatLng(lat, lon),
        infoWindow: InfoWindow(
          title: 'Station $id',
          snippet: 'Lat: $lat, Lng: $lon',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(_getHueFromColor(color)),
      );
      _markers.add(marker);
    }

    setState(() {});
  }

  // Parse color string to Color
  Color _parseColor(String colorString) {
    String hexColor = colorString.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // Get marker hue from color
  double _getHueFromColor(String colorString) {
    // Default colors for BitmapDescriptor have specific hues
    // This is a simple mapping of common blues to hues
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

  // Generate a color for the station based on its properties
  String _getColorForStation(Map<String, dynamic> station) {
    // In a real app, you might determine color based on flow data, favorites, etc.
    final List<String> colors = [
      '#2389da', // Light blue
      '#0074d9', // Blue
      '#0052cc', // Medium blue
      '#004080', // Dark blue
      '#001f3f', // Navy
    ];

    // Use the station ID to pick a color (consistently for same station)
    final id = station['stationId'] as int? ?? 0;
    final colorIndex = id % colors.length;
    return colors[colorIndex];
  }

  // NEW METHOD: Show map type selector bottom sheet
  void _showMapTypeSelector() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Standard'),
                onTap: () {
                  setState(() => _currentMapType = MapType.normal);
                  Navigator.pop(context);
                },
                selected: _currentMapType == MapType.normal,
              ),
              ListTile(
                leading: const Icon(Icons.satellite),
                title: const Text('Satellite'),
                onTap: () {
                  setState(() => _currentMapType = MapType.satellite);
                  Navigator.pop(context);
                },
                selected: _currentMapType == MapType.satellite,
              ),
              ListTile(
                leading: const Icon(Icons.terrain),
                title: const Text('Terrain'),
                onTap: () {
                  setState(() => _currentMapType = MapType.terrain);
                  Navigator.pop(context);
                },
                selected: _currentMapType == MapType.terrain,
              ),
              ListTile(
                leading: const Icon(Icons.layers),
                title: const Text('Hybrid'),
                onTap: () {
                  setState(() => _currentMapType = MapType.hybrid);
                  Navigator.pop(context);
                },
                selected: _currentMapType == MapType.hybrid,
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Rivr 3D Map Test'),
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh),
      //       onPressed:
      //           _currentZoom >= _minZoomForMarkers
      //               ? _loadStationsInVisibleRegion
      //               : null,
      //       tooltip: 'Refresh stations',
      //     ),
      //     // UPDATED: Changed the layers button to call _showMapTypeSelector()
      //     IconButton(
      //       icon: const Icon(Icons.layers),
      //       onPressed: _showMapTypeSelector,
      //       tooltip: 'Change map type',
      //     ),
      //     // NEW: Added a compare button to navigate to the Mapbox page
      //     IconButton(
      //       icon: const Icon(Icons.compare),
      //       onPressed: () {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(builder: (context) => const MapboxPage()),
      //         );
      //       },
      //       tooltip: 'Compare with Mapbox',
      //     ),
      //   ],
      // ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 5.0,
              tilt: _is3DMode ? 45.0 : 0.0, // Initial tilt for 3D effect
              bearing: 0,
            ),
            mapType: _currentMapType,
            markers: _markers,
            circles: _circles,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            tiltGesturesEnabled: true, // Enable tilt gestures
            rotateGesturesEnabled: true, // Enable rotate gestures
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
          ),

          // Status overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white.withOpacity(0.8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoading)
                      const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Loading stations...'),
                        ],
                      )
                    else if (_showZoomMessage)
                      Row(
                        children: [
                          Icon(
                            Icons.zoom_in,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Zoom in to see station markers',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Showing $_markerCount stations in view',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Total stations available: $_totalStationCount',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    if (!_isLoading &&
                        _loadDuration != null &&
                        _markerCount > 0)
                      Text(
                        'Loaded in ${_loadDuration!.inMilliseconds}ms',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    // NEW: Added label for current map type
                    Text(
                      'Map type: ${_currentMapType.toString().split('.').last}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in',
            onPressed: () {
              if (_mapController != null) {
                _mapController!.animateCamera(CameraUpdate.zoomIn());
              }
            },
            tooltip: 'Zoom in',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'zoom_out',
            onPressed: () {
              if (_mapController != null) {
                _mapController!.animateCamera(CameraUpdate.zoomOut());
              }
            },
            tooltip: 'Zoom out',
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'tilt',
            onPressed: _toggleTilt,
            tooltip: 'Toggle 3D view',
            child: const Icon(Icons.threed_rotation),
          ),
        ],
      ),
    );
  }

  // Toggle between 2D and 3D view
  void _toggleTilt() {
    if (_mapController != null) {
      // We need to get the current zoom level
      _mapController!.getZoomLevel().then((zoom) {
        // Create a new camera position with the current target
        final cameraPosition = CameraPosition(
          target:
              _visibleRegion != null
                  ? LatLng(
                    (_visibleRegion!.northeast.latitude +
                            _visibleRegion!.southwest.latitude) /
                        2,
                    (_visibleRegion!.northeast.longitude +
                            _visibleRegion!.southwest.longitude) /
                        2,
                  )
                  : _center,
          zoom: zoom,
          tilt: _is3DMode ? 0.0 : 45.0, // Toggle between 0 and 45 degrees
          bearing: 0.0,
        );

        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(cameraPosition),
        );

        setState(() {
          _is3DMode = !_is3DMode;
        });
      });
    }
  }

  // REMOVED: This method is no longer needed as it's replaced by _showMapTypeSelector()
  // void _toggleMapType() {
  //   setState(() {
  //     _currentMapType =
  //         _currentMapType == MapType.normal
  //             ? MapType.satellite
  //             : _currentMapType == MapType.satellite
  //             ? MapType.terrain
  //             : MapType.normal;
  //   });
  // }
}
