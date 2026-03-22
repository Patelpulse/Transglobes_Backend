import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get appName => dotenv.env['APP_NAME'] ?? 'RideShare';
  
  static String get apiBaseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    // Default fallback
    if (envUrl != null && envUrl.isNotEmpty && !kDebugMode) {
      return envUrl;
    }
    
    // For local development
    if (kIsWeb) return 'http://localhost:8080'; // Updated to localhost to bypass live SMTP blocking
    // 10.0.2.2 is the localhost address for Android emulators
    return 'http://10.0.2.2:8080';
  }
  
  // Google Maps API Key
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  // Service Types
  static const String serviceCab = 'cab';
  static const String serviceTruck = 'truck';
  static const String serviceBus = 'bus';
}

