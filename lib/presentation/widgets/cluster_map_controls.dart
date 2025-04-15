// lib/presentation/widgets/cluster_map_controls.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/cluster_map_provider.dart';

class ClusterMapControls extends StatelessWidget {
  const ClusterMapControls({super.key});

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<ClusterMapProvider>(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'zoom_in',
          onPressed: () {
            mapProvider.mapController?.animateCamera(CameraUpdate.zoomIn());
          },
          tooltip: 'Zoom in',
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'zoom_out',
          onPressed: () {
            mapProvider.mapController?.animateCamera(CameraUpdate.zoomOut());
          },
          tooltip: 'Zoom out',
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'tilt',
          onPressed: () {
            mapProvider.toggleTilt();
          },
          tooltip: 'Toggle 3D view',
          child: const Icon(Icons.threed_rotation),
        ),
      ],
    );
  }
}
