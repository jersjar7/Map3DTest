// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart' as di;
import 'core/environments/environment_config.dart';
import 'presentation/pages/map_page.dart';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await EnvironmentConfig.initialize();

  // Initialize dependencies
  await di.initServiceLocator();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: di.getProviders(),
      child: MaterialApp(
        title: '3D Map',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MapPage(),
      ),
    );
  }
}
