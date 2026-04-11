import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Transglobal';

  static const String _localBackendUrl = 'http://localhost:8082';
  static const String _defaultBackendUrl =
      'https://api.transgloble.com';
  static const String _overrideApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static bool get _isLocalhostWeb {
    if (!kIsWeb) return false;
    final host = Uri.base.host.toLowerCase();
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host == '::1';
  }

  static String get apiBaseUrl {
    if (_overrideApiBaseUrl.isNotEmpty) {
      return _overrideApiBaseUrl;
    }

    if (_isLocalhostWeb) {
      return _localBackendUrl;
    }

    return _defaultBackendUrl;
  }


  // Google Maps API Key (Replace with your key)
  static const String googleMapsApiKey = 'AIzaSyAJZ0z6ayXWTRsQzslL21I6CtYgW2X3sfQ';

  // Service Types
  static const String serviceCab = 'cab';
  static const String serviceTruck = 'truck';
  static const String serviceBus = 'bus';
}
