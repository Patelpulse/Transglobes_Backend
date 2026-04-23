class NetworkLogger {
  NetworkLogger._();

  static void logRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Object? body,
  }) {
    final curl = _toCurl(
      method: method,
      url: url,
      headers: headers ?? const <String, String>{},
      body: body,
    );
    print('\n========== API REQUEST ==========');
    print('METHOD: ${method.toUpperCase()}');
    print('URL: $url');
    if (headers != null && headers.isNotEmpty) {
      print('HEADERS: $headers');
    }
    if (body != null) {
      print('BODY: $body');
    }
    print('CURL: $curl');
    print('=================================\n');
  }

  static void logResponse({
    required String method,
    required Uri url,
    required int statusCode,
    required String responseBody,
  }) {
    print('\n========== API RESPONSE =========');
    print('METHOD: ${method.toUpperCase()}');
    print('URL: $url');
    print('STATUS: $statusCode');
    print('RESPONSE: $responseBody');
    print('=================================\n');
  }

  static void logError({
    required String method,
    required Uri url,
    required Object error,
  }) {
    print('\n========== API ERROR ============');
    print('METHOD: ${method.toUpperCase()}');
    print('URL: $url');
    print('ERROR: $error');
    print('=================================\n');
  }

  static String _toCurl({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    Object? body,
  }) {
    final buffer = StringBuffer();
    buffer.write("curl --location --request ${method.toUpperCase()} '$url'");
    headers.forEach((key, value) {
      final escapedValue = value.replaceAll("'", r"'\''");
      buffer.write(" --header '$key: $escapedValue'");
    });
    if (body != null) {
      final raw = body.toString().replaceAll("'", r"'\''");
      buffer.write(" --data-raw '$raw'");
    }
    return buffer.toString();
  }
}
