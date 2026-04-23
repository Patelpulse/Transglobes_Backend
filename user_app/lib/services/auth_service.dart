import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/api_endpoints.dart';
import 'network_logger.dart';

// Demo mode flag - set to false when you have real Firebase configured
const bool kDemoMode = false;

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<dynamic>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class MockUser {
  String? uid;
  String? displayName;
  String? email;
  String? phoneNumber;

  MockUser({
    this.uid = "demo-uid-123",
    this.displayName = "Yogesh Thakur",
    this.email = "yogesh@example.com",
    this.phoneNumber = "+91 98765 43210",
  });

  Future<void> updateDisplayName(String? name) async {
    displayName = name;
  }

  Future<void> updatePhoneNumber(String? phone) async {
    phoneNumber = phone;
  }
}

class AuthService {
  static const String _sessionTokenKey = 'user_auth_token';
  static const String _sessionUserKey = 'user_auth_user';
  static final MockUser _mockUser = MockUser();
  final StreamController<dynamic> _authStateController =
      StreamController<dynamic>.broadcast();
  MockUser? _sessionUser;
  String? _sessionToken;

  AuthService() {
    _restoreSession();
  }

  Future<void> waitForSession() async {
    await _restoreSession();
  }

  dynamic get currentUser => kDemoMode ? _mockUser : _sessionUser;

  Stream<dynamic> get authStateChanges => _authStateController.stream;

  Future<String?> getIdToken() async {
    if (kDemoMode) {
      return 'demo-token-for-testing';
    }

    if (_sessionToken != null && _sessionToken!.isNotEmpty) {
      return _sessionToken;
    }
    return kDebugMode ? 'dev-token-bypass' : null;
  }

  Future<Map<String, String>> buildAuthHeaders({
    bool includeContentType = true,
    Map<String, String>? extraHeaders,
  }) async {
    final token = await getIdToken();
    final headers = <String, String>{
      if (includeContentType) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final uid = currentUser?.uid?.toString();
    if (uid != null && uid.isNotEmpty) {
      headers['x-dev-uid'] = uid;
    }

    if (extraHeaders != null && extraHeaders.isNotEmpty) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionToken = prefs.getString(_sessionTokenKey);
    final rawUser = prefs.getString(_sessionUserKey);
    if (rawUser != null) {
      final decoded = json.decode(rawUser) as Map<String, dynamic>;
      _sessionUser = MockUser(
        uid: decoded['uid']?.toString(),
        displayName: decoded['name']?.toString(),
        email: decoded['email']?.toString(),
        phoneNumber: decoded['mobileNumber']?.toString(),
      );
    }
    _authStateController.add(_sessionUser);
  }

  Future<void> _saveSession(Map<String, dynamic> user, String? token) async {
    final prefs = await SharedPreferences.getInstance();
    _sessionToken = token ?? '';
    _sessionUser = MockUser(
      uid: user['uid']?.toString() ?? user['id']?.toString() ?? '',
      displayName: user['name']?.toString(),
      email: user['email']?.toString(),
      phoneNumber: user['mobileNumber']?.toString(),
    );
    await prefs.setString(_sessionTokenKey, _sessionToken!);
    await prefs.setString(_sessionUserKey, json.encode(user));
    _authStateController.add(_sessionUser);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final headers = await buildAuthHeaders();
    final url = Uri.parse('${AppConfig.apiBaseUrl}$path');
    NetworkLogger.logRequest(
      method: 'POST',
      url: url,
      headers: headers,
      body: body,
    );
    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );
    NetworkLogger.logResponse(method: 'POST', url: url, response: response);
    final data = response.body.isNotEmpty
        ? json.decode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    return {
      'success': response.statusCode == 200 || response.statusCode == 201,
      'statusCode': response.statusCode,
      'message': data['message']?.toString() ?? 'Request failed',
      'token': data['token']?.toString(),
      'user': data['user'],
      'raw': data,
    };
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String mobileNumber,
  }) async {
    final res = await _post(AuthEndpoints.userSignup, {
      'name': name,
      'email': email,
      'password': password,
      'mobileNumber': mobileNumber,
    });
    if (res['success'] == true && res['user'] is Map<String, dynamic>) {
      await _saveSession(res['user'] as Map<String, dynamic>, res['token'] as String?);
    }
    return res;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _post(AuthEndpoints.userLogin, {
      'email': email,
      'password': password,
    });
    if (res['success'] == true && res['user'] is Map<String, dynamic>) {
      await _saveSession(res['user'] as Map<String, dynamic>, res['token'] as String?);
    }
    return res;
  }

  Future<Map<String, dynamic>> mobileSignup({
    required String name,
    required String mobileNumber,
    required String password,
  }) async {
    final res = await _post(AuthEndpoints.userMobileSignup, {
      'name': name,
      'mobileNumber': mobileNumber,
      'password': password,
    });
    if (res['success'] == true && res['user'] is Map<String, dynamic>) {
      await _saveSession(res['user'] as Map<String, dynamic>, res['token'] as String?);
    }
    return res;
  }

  Future<Map<String, dynamic>> mobileLogin({
    required String mobileNumber,
    required String password,
  }) async {
    final res = await _post(AuthEndpoints.userMobileLogin, {
      'mobileNumber': mobileNumber,
      'password': password,
    });
    if (res['success'] == true && res['user'] is Map<String, dynamic>) {
      await _saveSession(res['user'] as Map<String, dynamic>, res['token'] as String?);
    }
    return res;
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final headers = await buildAuthHeaders(includeContentType: false);
    final url = Uri.parse('${AppConfig.apiBaseUrl}${AuthEndpoints.profile}');
    NetworkLogger.logRequest(method: 'GET', url: url, headers: headers);
    final response = await http.get(
      url,
      headers: headers,
    );
    NetworkLogger.logResponse(method: 'GET', url: url, response: response);
    final data = response.body.isNotEmpty
        ? json.decode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    return {
      'success': response.statusCode == 200,
      'statusCode': response.statusCode,
      'message': data['message']?.toString() ?? '',
      'user': data['user'],
    };
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String mobileNumber,
  }) async {
    final headers = await buildAuthHeaders();
    final url = Uri.parse('${AppConfig.apiBaseUrl}${AuthEndpoints.profile}');
    final body = {'name': name, 'mobileNumber': mobileNumber};
    NetworkLogger.logRequest(
      method: 'PUT',
      url: url,
      headers: headers,
      body: body,
    );
    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(body),
    );
    NetworkLogger.logResponse(method: 'PUT', url: url, response: response);
    final data = response.body.isNotEmpty
        ? json.decode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    if (response.statusCode == 200 && data['user'] is Map<String, dynamic>) {
      await _saveSession(data['user'] as Map<String, dynamic>, _sessionToken);
    }
    return {
      'success': response.statusCode == 200,
      'message': data['message']?.toString() ?? 'Update failed',
      'user': data['user'],
    };
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionTokenKey);
    await prefs.remove(_sessionUserKey);
    _sessionToken = null;
    _sessionUser = null;
    _authStateController.add(null);
  }

  Future<void> resetPassword(String email) async {
    // Not wired to backend reset API yet.
    throw UnimplementedError('Password reset API not configured');
  }
}
