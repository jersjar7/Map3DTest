// lib/presentation/pages/map_page.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../providers/map_provider.dart';
import '../widgets/map_controls.dart';
import '../widgets/map_info_overlay.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: () => _showMapTypeSelector(context),
            tooltip: 'Change map type',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: mapProvider.onMapCreated,
            initialCameraPosition: CameraPosition(
              target: const LatLng(
                AppConstants.defaultLatitude,
                AppConstants.defaultLongitude,
              ),
              zoom: AppConstants.defaultZoom,
              tilt: mapProvider.is3DMode ? AppConstants.defaultTilt : 0.0,
              bearing: 0,
            ),
            mapType: mapProvider.currentMapType,
            markers: mapProvider.markers,
            circles: mapProvider.circles,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            onCameraMove: mapProvider.onCameraMove,
            onCameraIdle: mapProvider.onCameraIdle,
          ),
          const MapInfoOverlay(),
        ],
      ),
      floatingActionButton: const MapControls(),
    );
  }

  void _showMapTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final mapProvider = Provider.of<MapProvider>(context, listen: false);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Standard'),
              selected: mapProvider.currentMapType == MapType.normal,
              onTap: () {
                mapProvider.changeMapType(MapType.normal);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.satellite),
              title: const Text('Satellite'),
              selected: mapProvider.currentMapType == MapType.satellite,
              onTap: () {
                mapProvider.changeMapType(MapType.satellite);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.terrain),
              title: const Text('Terrain'),
              selected: mapProvider.currentMapType == MapType.terrain,
              onTap: () {
                mapProvider.changeMapType(MapType.terrain);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers),
              title: const Text('Hybrid'),
              selected: mapProvider.currentMapType == MapType.hybrid,
              onTap: () {
                mapProvider.changeMapType(MapType.hybrid);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
