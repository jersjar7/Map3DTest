// lib/core/environments/environment_config.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Manages environment-specific configuration values
class EnvironmentConfig {
  static final EnvironmentConfig _instance = EnvironmentConfig._internal();
  factory EnvironmentConfig() => _instance;

  EnvironmentConfig._internal();

  /// Initializes the environment configuration
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('Environment loaded successfully');
    } catch (e) {
      debugPrint('Failed to load environment file: $e');
      rethrow;
    }
  }

  /// Gets the Google Maps API key from environment variables
  String get googleMapsApiKey {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (key == null || key.isEmpty) {
      debugPrint('Warning: No Google Maps API key found in environment');
      return '';
    }
    return key;
  }
}
