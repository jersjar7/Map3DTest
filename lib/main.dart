// In lib/main.dart

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'map_3d_page.dart';

void main() {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Set your Mapbox access token
  // You can pass this via flutter run --dart-define ACCESS_TOKEN=your_token
  // or hardcode it for development (not recommended for production)
  final String mapboxAccessToken = const String.fromEnvironment(
    'ACCESS_TOKEN',
    defaultValue:
        'sk.eyJ1IjoiamVyc29uZGV2cyIsImEiOiJjbTkxdjJkZHEwNWY5MmluNnp0YzEwNGFmIn0.2BnxGcaNrneHqx_clzpvHg',
  );

  // Initialize Mapbox
  MapboxOptions.setAccessToken(mapboxAccessToken);

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map 3D Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Map3DPage(),
    );
  }
}
