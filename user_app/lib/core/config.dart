class AppConfig {
  static const String appName = 'Transglobal';

  static const String _defaultBackendUrl =
      'https://api.transgloble.com';
  static const String _overrideApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    return _overrideApiBaseUrl.isNotEmpty
        ? _overrideApiBaseUrl
        : _defaultBackendUrl;
  }


  // Google Maps API Key (Replace with your key)
  static const String googleMapsApiKey = 'AIzaSyAJZ0z6ayXWTRsQzslL21I6CtYgW2X3sfQ';

  // Service Types
  static const String serviceCab = 'cab';
  static const String serviceTruck = 'truck';
  static const String serviceBus = 'bus';
}
