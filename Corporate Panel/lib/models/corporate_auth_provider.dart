import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
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
    const String prodUrl = 'https://api.transgloble.com';
    const String localUrl = 'http://localhost:8082';

    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      if (host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '0.0.0.0' ||
          host == '::1') {
        return localUrl;
      }
    }

    return prodUrl;
  }

  CorporateAccount? _account;
  String? _token;
  bool _isLoading = false;
  String? _error;

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

  Map<String, dynamic> _parseResponse(http.Response response) {
    final body = response.body.trim();
    final contentType = response.headers['content-type'] ?? '';
    final looksLikeJson = body.startsWith('{') || body.startsWith('[');

    if (contentType.contains('application/json') || looksLikeJson) {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }

    final missingGoogleSyncRoute = body.contains('Cannot POST /api/corporate/google-sync');
    return {
      'success': false,
      'message': missingGoogleSyncRoute
          ? 'Google sign-in is not enabled on the current backend deployment. Please deploy the backend route `/api/corporate/google-sync` or use email/password for now.'
          : 'Unexpected server response (${response.statusCode}). The server returned HTML instead of JSON.',
    };
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/corporate/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim(),
          'password': password,
        }),
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['success'] == true) {
        _token = data['token']?.toString();
        _account = CorporateAccount.fromMap(
          Map<String, dynamic>.from(data['corporate'] as Map),
        );
        _saveSession();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = data['message']?.toString() ?? 'Login failed';
    } catch (e) {
      _error = 'Failed to connect to corporate login service.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        _error = 'Failed to get Google token.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/corporate/google-sync'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(const {}),
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['success'] == true) {
        _token = data['token']?.toString();
        _account = CorporateAccount.fromMap(
          Map<String, dynamic>.from(data['corporate'] as Map),
        );
        _saveSession();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = data['message']?.toString() ?? 'Google sign-in failed.';
    } catch (e) {
      _error = 'Google sign-in error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _account = null;
    _token = null;
    _error = null;
    clearCorporateSession();
    FirebaseAuth.instance.signOut();
    notifyListeners();
  }
}
