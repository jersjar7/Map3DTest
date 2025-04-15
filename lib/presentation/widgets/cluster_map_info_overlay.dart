// lib/presentation/widgets/cluster_map_info_overlay.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cluster_map_provider.dart';

class ClusterMapInfoOverlay extends StatelessWidget {
  const ClusterMapInfoOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<ClusterMapProvider>(context);

    return Positioned(
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
              if (mapProvider.isLoading)
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
              else if (mapProvider.showZoomMessage)
                Row(
                  children: [
                    Icon(Icons.zoom_in, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Zoom in to see station clusters',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Showing ${mapProvider.markerCount} markers (clustered)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 4),
              Text(
                'Total stations available: ${mapProvider.totalStationCount}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              if (!mapProvider.isLoading && mapProvider.loadDuration != null)
                Text(
                  'Loaded in ${mapProvider.loadDuration!.inMilliseconds}ms',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              Text(
                'Map type: ${mapProvider.currentMapType.toString().split('.').last}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
