import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String _defaultBackendUrl = 'http://72.61.172.182:2020';
  static const String _overrideApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _vpsBackendUrl = 'http://72.61.172.182:2020';

  static bool get _isVpsWeb {
    if (!kIsWeb) return false;
    final host = Uri.base.host.toLowerCase();
    final port = Uri.base.port;
    return host == '72.61.172.182' && port == 2020;
  }

  static String get apiBaseUrl {
    if (_overrideApiBaseUrl.isNotEmpty) {
      return _overrideApiBaseUrl;
    }
    if (_isVpsWeb) {
      return _vpsBackendUrl;
    }
    return _defaultBackendUrl;
  }
}
