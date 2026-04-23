import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';
import '../core/network_logger.dart';
import 'auth_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiService(authService);
});

class ApiService {
  final AuthService _authService;
  final String baseUrl = AppConfig.apiBaseUrl;

  ApiService(this._authService);

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    NetworkLogger.logRequest(method: 'GET', url: uri, headers: headers);
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response, method: 'GET', url: uri);
  }

  Future<dynamic> getWithFallback(
    String primaryEndpoint,
    String fallbackEndpoint,
  ) async {
    try {
      return await get(primaryEndpoint);
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      return get(fallbackEndpoint);
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    final encodedBody = jsonEncode(body);
    NetworkLogger.logRequest(
      method: 'POST',
      url: uri,
      headers: headers,
      body: encodedBody,
    );
    final response = await http.post(
      uri,
      headers: headers,
      body: encodedBody,
    );
    return _handleResponse(response, method: 'POST', url: uri);
  }

  Future<dynamic> postWithFallback(
    String primaryEndpoint,
    String fallbackEndpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      return await post(primaryEndpoint, body);
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      return post(fallbackEndpoint, body);
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    final encodedBody = jsonEncode(body);
    NetworkLogger.logRequest(
      method: 'PUT',
      url: uri,
      headers: headers,
      body: encodedBody,
    );
    final response = await http.put(
      uri,
      headers: headers,
      body: encodedBody,
    );
    return _handleResponse(response, method: 'PUT', url: uri);
  }

  Future<dynamic> putWithFallback(
    String primaryEndpoint,
    String fallbackEndpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      return await put(primaryEndpoint, body);
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      return put(fallbackEndpoint, body);
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    final encodedBody = jsonEncode(body);
    NetworkLogger.logRequest(
      method: 'PATCH',
      url: uri,
      headers: headers,
      body: encodedBody,
    );
    final response = await http.patch(
      uri,
      headers: headers,
      body: encodedBody,
    );
    return _handleResponse(response, method: 'PATCH', url: uri);
  }

  Future<dynamic> patchWithFallback(
    String primaryEndpoint,
    String fallbackEndpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      return await patch(primaryEndpoint, body);
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      return patch(fallbackEndpoint, body);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    NetworkLogger.logRequest(method: 'DELETE', url: uri, headers: headers);
    final response = await http.delete(uri, headers: headers);
    return _handleResponse(response, method: 'DELETE', url: uri);
  }

  dynamic _handleResponse(
    http.Response response, {
    required String method,
    required Uri url,
  }) {
    NetworkLogger.logResponse(
      method: method,
      url: url,
      statusCode: response.statusCode,
      responseBody: response.body,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: $statusCode - $message';
}
