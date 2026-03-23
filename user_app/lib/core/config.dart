import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Transglobal';
  static String get apiBaseUrl {
    if (kDebugMode) {
      if (kIsWeb) return 'http://localhost:8000';
      // 10.0.2.2 is the localhost address for Android emulators
      return 'http://10.0.2.2:8000';
    }
    return 'https://transglobesbackend-production.up.railway.app';
  }


  // Google Maps API Key (Replace with your key)
  static const String googleMapsApiKey = 'AIzaSyAJZ0z6ayXWTRsQzslL21I6CtYgW2X3sfQ';

  // Service Types
  static const String serviceCab = 'cab';
  static const String serviceTruck = 'truck';
  static const String serviceBus = 'bus';
}
