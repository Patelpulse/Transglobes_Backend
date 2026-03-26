import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get appName => dotenv.env['APP_NAME'] ?? 'RideShare';
  
  static String get apiBaseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    return 'http://localhost:8080/api';
  }

  // Socket server root (WITHOUT /api suffix)
  static String get socketBaseUrl {
    final envUrl = dotenv.env['SOCKET_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    return 'http://localhost:8080';
  }
  
  // Google Maps API Key
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  // Service Types
  static const String serviceCab = 'cab';
  static const String serviceTruck = 'truck';
  static const String serviceBus = 'bus';
}

