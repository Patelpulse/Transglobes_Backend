import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Transglobal';
  static String get apiBaseUrl {
    if (kDebugMode) {
      if (kIsWeb) return 'http://localhost:8000';
      return 'http://10.0.2.2:8000';
    }
    return 'https://transglove-backend.onrender.com';
  }


  // Google Maps API Key (Replace with your key)
  static const String googleMapsApiKey = 'AIzaSyC7SGsD3I7EOEKDh8VXchJGSYz6dnLqM4I';

  // Service Types
  static const String serviceCab = 'cab';
  static const String serviceTruck = 'truck';
  static const String serviceBus = 'bus';
}
