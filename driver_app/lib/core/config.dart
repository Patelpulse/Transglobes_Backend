import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get appName => dotenv.env['APP_NAME'] ?? 'RideShare';

  static const String _defaultBackendUrl = 'http://72.61.172.182:2020';
  static const String _overrideApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _overrideSocketBaseUrl = String.fromEnvironment(
    'SOCKET_BASE_URL',
    defaultValue: '',
  );

  static const String _vpsBackendUrl = 'http://72.61.172.182:2020';

  static bool get _isVpsWeb {
    if (!kIsWeb) return false;
    final h = Uri.base.host.toLowerCase();
    final p = Uri.base.port;
    return h == '72.61.172.182' && p == 2020;
  }
  
  static String get apiBaseUrl {
    if (_overrideApiBaseUrl.isNotEmpty) {
      return _overrideApiBaseUrl;
    }
    if (_isVpsWeb) {
      return _vpsBackendUrl;
    }
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    return _defaultBackendUrl;
  }

  // Socket server root (WITHOUT /api suffix)
  static String get socketBaseUrl {
    if (_overrideSocketBaseUrl.isNotEmpty) {
      return _overrideSocketBaseUrl;
    }
    if (_isVpsWeb) {
      return _vpsBackendUrl;
    }
    final envUrl = dotenv.env['SOCKET_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    return _defaultBackendUrl;
  }
  
  // Google Maps API Key
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  // Service Types
  static const String serviceCab = 'cab';
  static const String serviceTruck = 'truck';
  static const String serviceBus = 'bus';
}
