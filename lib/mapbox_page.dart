// In lib/mapbox_page.dart

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxPage extends StatefulWidget {
  const MapboxPage({super.key});

  @override
  State<MapboxPage> createState() => _MapboxPageState();
}

class _MapboxPageState extends State<MapboxPage> {
  MapboxMap? _mapboxMap;
  String _currentStyle = MapboxStyles.MAPBOX_STREETS;
  bool _is3DMode = true;

  // Default center coordinates (same as Google Maps page)
  final Point _center = Point(coordinates: Position(-111.658531, 40.233845));

  // Available Mapbox map styles
  final Map<String, String> _mapStyles = {
    'Streets': MapboxStyles.MAPBOX_STREETS,
    'Light': MapboxStyles.LIGHT,
    'Dark': MapboxStyles.DARK,
    'Satellite': MapboxStyles.SATELLITE,
  };

  @override
  void initState() {
    super.initState();
    // Access token should be set in main.dart
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    // Set initial camera
    _setInitialCamera();
  }

  Future<void> _setInitialCamera() async {
    if (_mapboxMap == null) return;

    try {
      // Set camera pitch for 3D effect
      if (_is3DMode) {
        await _setCameraPitch(60);
      }
    } catch (e) {
      print('Error setting initial camera: $e');
    }
  }

  // Show style selector
  void _showStyleSelector() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children:
                _mapStyles.entries.map((entry) {
                  return ListTile(
                    title: Text(entry.key),
                    selected: _currentStyle == entry.value,
                    onTap: () {
                      setState(() {
                        _currentStyle = entry.value;
                      });
                      // Update map style
                      if (_mapboxMap != null) {
                        _mapboxMap!.loadStyleURI(_currentStyle);
                      }
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
          ),
    );
  }

  // Toggle 3D terrain
  void _toggle3DTerrain() {
    setState(() {
      _is3DMode = !_is3DMode;
    });

    if (_mapboxMap == null) return;

    // Set camera pitch based on 3D mode
    _setCameraPitch(_is3DMode ? 60 : 0);
  }

  // Set camera pitch
  Future<void> _setCameraPitch(double pitch) async {
    if (_mapboxMap == null) return;

    try {
      var cameraState = await _mapboxMap!.getCameraState();
      var cameraOptions = CameraOptions(
        center: cameraState.center,
        zoom: cameraState.zoom,
        bearing: cameraState.bearing,
        pitch: pitch,
      );
      await _mapboxMap!.setCamera(cameraOptions);
    } catch (e) {
      print('Error setting camera pitch: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapbox 3D Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showStyleSelector,
            tooltip: 'Change map style',
          ),
        ],
      ),
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mapWidget'),
            onMapCreated: _onMapCreated,
            cameraOptions: CameraOptions(
              center: _center,
              zoom: 5.0,
              pitch: _is3DMode ? 60.0 : 0.0,
              bearing: 0,
            ),
            styleUri: _currentStyle,
          ),

          // Info overlay
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
                    const Text(
                      'Mapbox 3D Map',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current style: ${_mapStyles.entries.firstWhere((entry) => entry.value == _currentStyle, orElse: () => const MapEntry('Unknown', '')).key}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    Text(
                      '3D Mode: ${_is3DMode ? 'Enabled' : 'Disabled'}',
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
              if (_mapboxMap != null) {
                _mapboxMap!.getCameraState().then((cameraState) {
                  _mapboxMap!.setCamera(
                    CameraOptions(zoom: cameraState.zoom + 1),
                  );
                });
              }
            },
            tooltip: 'Zoom in',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'zoom_out',
            onPressed: () {
              if (_mapboxMap != null) {
                _mapboxMap!.getCameraState().then((cameraState) {
                  _mapboxMap!.setCamera(
                    CameraOptions(zoom: cameraState.zoom - 1),
                  );
                });
              }
            },
            tooltip: 'Zoom out',
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'tilt',
            onPressed: _toggle3DTerrain,
            tooltip: 'Toggle 3D view',
            child: const Icon(Icons.threed_rotation),
          ),
        ],
      ),
    );
  }
}
