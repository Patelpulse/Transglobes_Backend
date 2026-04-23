import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/api_endpoints.dart';
import '../core/network_logger.dart';

class AuthApiService {
  Future<Map<String, dynamic>> signUpDriverWithEmail({
    required String name,
    required String email,
    required String password,
    required String aadharCard,
    required String panCard,
    String? bearerToken,
  }) async {
    final url =
        Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.driverEmailSignup}');
    return _post(
      url: url,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'aadharCard': aadharCard,
        'panCard': panCard,
      },
      bearerToken: bearerToken,
    );
  }

  Future<Map<String, dynamic>> signInDriverWithEmail({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.driverEmailLogin}');
    return _post(
      url: url,
      body: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> signUpDriverWithMobile({
    required String name,
    required String mobileNumber,
    required String password,
  }) async {
    final url =
        Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.driverMobileSignup}');
    return _post(
      url: url,
      body: {
        'name': name,
        'mobileNumber': mobileNumber,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> signInDriverWithMobile({
    required String mobileNumber,
    required String password,
  }) async {
    final url =
        Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.driverMobileLogin}');
    return _post(
      url: url,
      body: {
        'mobileNumber': mobileNumber,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> signInDriverWithGoogle({
    required String googleIdToken,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.driverGoogleAuth}');
    return _post(
      url: url,
      body: const {},
      bearerToken: googleIdToken,
    );
  }

  Future<Map<String, dynamic>> getAuthProfile({
    required String authToken,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.authProfile}');
    return _request(
      method: 'GET',
      url: url,
      bearerToken: authToken,
    );
  }

  Future<Map<String, dynamic>> updateAuthProfile({
    required String authToken,
    required Map<String, dynamic> payload,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.authProfile}');
    return _request(
      method: 'PUT',
      url: url,
      body: payload,
      bearerToken: authToken,
    );
  }

  Future<Map<String, dynamic>> _post({
    required Uri url,
    required Map<String, dynamic> body,
    String? bearerToken,
  }) async {
    return _request(
      method: 'POST',
      url: url,
      body: body,
      bearerToken: bearerToken,
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required Uri url,
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    late final http.Response response;
    final headers = {
      'Content-Type': 'application/json',
      if (bearerToken != null && bearerToken.isNotEmpty)
        'Authorization': 'Bearer $bearerToken',
    };

    if (method == 'GET') {
      NetworkLogger.logRequest(method: method, url: url, headers: headers);
      response = await http.get(url, headers: headers);
    } else if (method == 'PUT') {
      NetworkLogger.logRequest(
        method: method,
        url: url,
        headers: headers,
        body: json.encode(body ?? <String, dynamic>{}),
      );
      response = await http.put(
        url,
        headers: headers,
        body: json.encode(body ?? <String, dynamic>{}),
      );
    } else {
      NetworkLogger.logRequest(
        method: method,
        url: url,
        headers: headers,
        body: json.encode(body ?? <String, dynamic>{}),
      );
      response = await http.post(
        url,
        headers: headers,
        body: json.encode(body ?? <String, dynamic>{}),
      );
    }
    NetworkLogger.logResponse(
      method: method,
      url: url,
      statusCode: response.statusCode,
      responseBody: response.body,
    );

    Map<String, dynamic> data = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    }

    final profile = (data['driver'] ?? data['user'] ?? data['profile']);
    return {
      'success': response.statusCode == 200 || response.statusCode == 201,
      'statusCode': response.statusCode,
      'message': data['message']?.toString() ?? 'Request failed',
      'token': data['token'],
      'user': profile is Map<String, dynamic> ? profile : null,
      'raw': data,
    };
  }
}
