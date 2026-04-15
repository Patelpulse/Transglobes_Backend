import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get appName => dotenv.env['APP_NAME'] ?? 'RideShare';

  static const String _defaultBackendUrl = 'https://api.transgloble.com';
  static const String _localBackendUrl = 'http://localhost:8082';
  static const String _overrideApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _overrideSocketBaseUrl = String.fromEnvironment(
    'SOCKET_BASE_URL',
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

  static const String _vpsBackendUrl = 'http://72.61.172.182:8085';

  static bool get _isVpsWeb {
    if (!kIsWeb) return false;
    final h = Uri.base.host.toLowerCase();
    final p = Uri.base.port;
    return h == '72.61.172.182' && p == 8085;
  }
  
  static String get apiBaseUrl {
    if (_overrideApiBaseUrl.isNotEmpty) {
      return _overrideApiBaseUrl;
    }
    if (_isVpsWeb) {
      return _vpsBackendUrl;
    }
    if (_isLocalhostWeb) {
      return _localBackendUrl;
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
    if (_isLocalhostWeb) {
      return _localBackendUrl;
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
