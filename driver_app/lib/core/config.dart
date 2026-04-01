import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get appName => dotenv.env['APP_NAME'] ?? 'RideShare';
  
  static String get apiBaseUrl {
    if (kIsWeb) {
      return Uri.base.origin;
    }

    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    return 'https://transglobesbackend-production.up.railway.app';
  }

  // Socket server root (WITHOUT /api suffix)
  static String get socketBaseUrl {
    if (kIsWeb) {
      return Uri.base.origin;
    }

    final envUrl = dotenv.env['SOCKET_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    return 'https://transglobesbackend-production.up.railway.app';
  }
  
  // Google Maps API Key
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  // Service Types
  static const String serviceCab = 'cab';
  static const String serviceTruck = 'truck';
  static const String serviceBus = 'bus';
}
