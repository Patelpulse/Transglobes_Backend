import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/api_endpoints.dart';
import '../core/config.dart';
import '../core/network_logger.dart';
import '../services/session_storage.dart';

class CorporateAccount {
  final String id;
  final String companyName;
  final String email;
  final String contactPhone;
  final String address;
  final String gstin;
  final String status;

  const CorporateAccount({
    required this.id,
    required this.companyName,
    required this.email,
    required this.contactPhone,
    required this.address,
    required this.gstin,
    required this.status,
  });

  factory CorporateAccount.fromMap(Map<String, dynamic> map) {
    return CorporateAccount(
      id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
      companyName: map['companyName']?.toString() ?? 'Corporate Partner',
      email: map['email']?.toString() ?? '',
      contactPhone: map['contactPhone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      gstin: map['gstin']?.toString() ?? '',
      status: map['status']?.toString() ?? 'active',
    );
  }
}

class CorporateAuthProvider with ChangeNotifier {
  static String get _baseUrl {
    return AppConfig.apiBaseUrl;
  }

  CorporateAccount? _account;
  String? _token;
  bool _isLoading = false;
  String? _error;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const <String>['email'],
  );

  CorporateAuthProvider() {
    _restoreSession();
  }

  CorporateAccount? get account => _account;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _account != null && _token != null;

  void _restoreSession() {
    try {
      final session = readCorporateSession();
      final token = session['token'];
      final accountJson = session['account'];

      if (token == null || accountJson == null) return;

      final decoded = json.decode(accountJson);
      if (decoded is Map<String, dynamic>) {
        _token = token;
        _account = CorporateAccount.fromMap(decoded);
      }
    } catch (_) {
      clearCorporateSession();
    }
  }

  void _saveSession() {
    if (_token == null || _account == null) return;

    writeCorporateSession(
      token: _token!,
      accountJson: json.encode({
        'id': _account!.id,
        'companyName': _account!.companyName,
        'email': _account!.email,
        'contactPhone': _account!.contactPhone,
        'address': _account!.address,
        'gstin': _account!.gstin,
        'status': _account!.status,
      }),
    );
  }

  Future<http.Response> _postWithFallback({
    required String primaryPath,
    required String fallbackPath,
    required Map<String, String> headers,
    Object? body,
  }) async {
    final primaryUrl = Uri.parse('$_baseUrl$primaryPath');
    NetworkLogger.logRequest(
      method: 'POST',
      url: primaryUrl,
      headers: headers,
      body: body,
    );
    final primary = await http.post(primaryUrl, headers: headers, body: body);
    NetworkLogger.logResponse(
        method: 'POST', url: primaryUrl, response: primary);
    if (primary.statusCode != 404) return primary;
    final fallbackUrl = Uri.parse('$_baseUrl$fallbackPath');
    NetworkLogger.logRequest(
      method: 'POST',
      url: fallbackUrl,
      headers: headers,
      body: body,
    );
    final fallback = await http.post(fallbackUrl, headers: headers, body: body);
    NetworkLogger.logResponse(
      method: 'POST',
      url: fallbackUrl,
      response: fallback,
    );
    return fallback;
  }

  Future<http.Response> _getWithFallback({
    required String primaryPath,
    required String fallbackPath,
    required Map<String, String> headers,
  }) async {
    final primaryUrl = Uri.parse('$_baseUrl$primaryPath');
    NetworkLogger.logRequest(
      method: 'GET',
      url: primaryUrl,
      headers: headers,
    );
    final primary = await http.get(primaryUrl, headers: headers);
    NetworkLogger.logResponse(
        method: 'GET', url: primaryUrl, response: primary);
    if (primary.statusCode != 404) return primary;
    final fallbackUrl = Uri.parse('$_baseUrl$fallbackPath');
    NetworkLogger.logRequest(
      method: 'GET',
      url: fallbackUrl,
      headers: headers,
    );
    final fallback = await http.get(fallbackUrl, headers: headers);
    NetworkLogger.logResponse(
      method: 'GET',
      url: fallbackUrl,
      response: fallback,
    );
    return fallback;
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final body = response.body.trim();
    final contentType = response.headers['content-type'] ?? '';
    final looksLikeJson = body.startsWith('{') || body.startsWith('[');

    if (contentType.contains('application/json') || looksLikeJson) {
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        // Fall through to synthetic error payload below.
      }
    }

    final missingGoogleSyncRoute = body.contains(
      'Cannot POST /api/auth/corporate/google-auth',
    );
    return {
      'success': false,
      'message': missingGoogleSyncRoute
          ? 'Google sign-in is not enabled on the current backend deployment. Please deploy `/api/auth/corporate/google-auth` or use email/mobile auth for now.'
          : 'Unexpected server response (${response.statusCode}). The server returned HTML instead of JSON.',
    };
  }

  CorporateAccount? _extractAccount(Map<String, dynamic> data) {
    final dynamic profile =
        data['corporate'] ?? data['user'] ?? data['profile'] ?? data['data'];
    if (profile is Map<String, dynamic>) {
      return CorporateAccount.fromMap(profile);
    }
    if (profile is Map) {
      return CorporateAccount.fromMap(Map<String, dynamic>.from(profile));
    }
    return null;
  }

  bool _isHttpSuccess(http.Response response) {
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<void> _syncProfileFromApi() async {
    if (_token == null || _token!.isEmpty) return;
    try {
      final response = await _getWithFallback(
        primaryPath: ApiEndpoints.corporateProfile,
        fallbackPath: ApiEndpoints.authProfile,
        headers: {'Authorization': 'Bearer $_token'},
      );
      final data = _parseResponse(response);
      final profile = _extractAccount(data);
      if (_isHttpSuccess(response) && profile != null) {
        _account = profile;
      }
    } catch (_) {
      // Keep existing account payload if profile endpoint fails.
    }
  }

  Future<bool> _authenticate({
    required String primaryPath,
    required String fallbackPath,
    required Map<String, dynamic> payload,
    Map<String, String>? extraHeaders,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _postWithFallback(
        primaryPath: primaryPath,
        fallbackPath: fallbackPath,
        headers: {
          'Content-Type': 'application/json',
          if (extraHeaders != null) ...extraHeaders,
        },
        body: json.encode(payload),
      );

      final data = _parseResponse(response);
      if (_isHttpSuccess(response)) {
        _token = data['token']?.toString();
        _account = _extractAccount(data);
        await _syncProfileFromApi();
        if (_token != null && _account != null) {
          _saveSession();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _error = data['message']?.toString() ?? 'Authentication failed';
    } catch (e) {
      NetworkLogger.logError(
        method: 'POST',
        url: Uri.parse('$_baseUrl$primaryPath'),
        error: e,
      );
      _error = 'Failed to connect to corporate auth service.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    return loginWithEmail(email: email, password: password);
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) {
    return _authenticate(
      primaryPath: ApiEndpoints.corporateEmailLogin,
      fallbackPath: ApiEndpoints.corporateLegacyLogin,
      payload: {
        'email': email.trim(),
        'password': password,
      },
    );
  }

  Future<bool> loginWithMobile({
    required String mobileNumber,
    required String password,
  }) {
    return _authenticate(
      primaryPath: ApiEndpoints.corporateMobileLogin,
      fallbackPath: ApiEndpoints.corporateLegacyMobileLogin,
      payload: {
        'mobileNumber': mobileNumber.trim(),
        'password': password,
      },
    );
  }

  Future<bool> signupWithEmail({
    required String companyName,
    required String gstin,
    required String email,
    required String contactPhone,
    required String address,
    required String password,
  }) {
    return _authenticate(
      primaryPath: ApiEndpoints.corporateEmailSignup,
      fallbackPath: ApiEndpoints.corporateLegacySignup,
      payload: {
        'companyName': companyName.trim(),
        'gstin': gstin.trim(),
        'email': email.trim(),
        'contactPhone': contactPhone.trim(),
        'address': address.trim(),
        'password': password,
      },
    );
  }

  Future<bool> signupWithMobile({
    required String companyName,
    required String gstin,
    required String mobileNumber,
    required String contactPhone,
    required String address,
    required String password,
  }) {
    return _authenticate(
      primaryPath: ApiEndpoints.corporateMobileSignup,
      fallbackPath: ApiEndpoints.corporateLegacyMobileSignup,
      payload: {
        'companyName': companyName.trim(),
        'gstin': gstin.trim(),
        'mobileNumber': mobileNumber.trim(),
        'contactPhone': contactPhone.trim(),
        'address': address.trim(),
        'password': password,
      },
    );
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _error = 'Google sign-in was cancelled.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        _error = 'Failed to obtain Google authentication tokens.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        _error = 'Failed to get Google token.';
        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await _postWithFallback(
        primaryPath: ApiEndpoints.corporateGoogleAuth,
        fallbackPath: ApiEndpoints.corporateLegacyGoogleAuth,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'companyName': userCredential.user?.displayName ?? 'Google Corporate',
          'contactPhone': '',
          'address': '',
          'gstin': '',
        }),
      );

      final data = _parseResponse(response);
      if (_isHttpSuccess(response)) {
        _token = data['token']?.toString();
        _account = _extractAccount(data);
        await _syncProfileFromApi();
        if (_token != null && _account != null) {
          _saveSession();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _error = data['message']?.toString() ?? 'Google sign-in failed.';
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      NetworkLogger.logError(
        method: 'POST',
        url: Uri.parse('$_baseUrl${ApiEndpoints.corporateGoogleAuth}'),
        error: e,
      );
      _error = 'Google sign-in error: ${e.toString()}';
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _account = null;
    _token = null;
    _error = null;
    clearCorporateSession();
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }
}
