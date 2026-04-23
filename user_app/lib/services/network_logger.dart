import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NetworkLogger {
  static void logRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? formFields,
  }) {
    debugPrint('[API][REQUEST] $method $url');
    debugPrint('[API][CURL] ${_buildCurl(method, url, headers, body, formFields)}');
    if (body != null) {
      debugPrint('[API][BODY] ${_stringify(body)}');
    }
    if (formFields != null && formFields.isNotEmpty) {
      debugPrint('[API][FORM] ${jsonEncode(formFields)}');
    }
  }

  static void logResponse({
    required String method,
    required Uri url,
    required http.Response response,
  }) {
    debugPrint('[API][RESPONSE] $method $url -> ${response.statusCode}');
    debugPrint('[API][RESPONSE_BODY] ${response.body}');
  }

  static void logError({
    required String method,
    required Uri url,
    required Object error,
  }) {
    debugPrint('[API][ERROR] $method $url -> $error');
  }

  static String _buildCurl(
    String method,
    Uri url,
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? formFields,
  ) {
    final segments = <String>[
      'curl -X $method',
      "'${_escape(url.toString())}'",
    ];

    if (headers != null) {
      headers.forEach((key, value) {
        segments.add("-H '${_escape('$key: $value')}'");
      });
    }

    if (body != null) {
      segments.add("--data '${_escape(_stringify(body))}'");
    }

    if (formFields != null) {
      formFields.forEach((key, value) {
        segments.add("-F '${_escape('$key=$value')}'");
      });
    }

    return segments.join(' ');
  }

  static String _stringify(Object body) {
    if (body is String) return body;
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  static String _escape(String value) {
    return value.replaceAll("'", "'\"'\"'");
  }
}
