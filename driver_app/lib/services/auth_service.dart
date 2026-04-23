import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/id_generator.dart';
import 'dart:convert';

import 'database_service.dart';
import 'auth_api_service.dart';

// Demo mode flag - set to false when you have real Firebase configured
// Google Sign-In always uses real Firebase (bypasses demo mode)
const bool kDemoMode = false;

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<dynamic>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final isOnboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final dbService = ref.watch(databaseServiceProvider);
  final user = authService.currentUser;
  print('[ONBOARD-DEBUG] Initializing status check for user: ${user?.uid}');
  if (user == null) {
    print('[ONBOARD-DEBUG] No user found. Defaulting to false.');
    return false;
  }

  final token = await authService.getIdToken();
  print(
      '[ONBOARD-DEBUG] Token retrieved (is null: ${token == null}). Checking backend...');
  final res = await dbService.isOnboardingComplete(
      user.uid, token ?? 'dev-token-bypass');
  print('[ONBOARD-DEBUG] Backend status check completed: $res');
  return res;
});

class MockUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  MockUser({required this.uid, this.email, this.displayName, this.photoURL});
}

class AuthService {
  FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const <String>['email'],
  );
  final AuthApiService _authApi = AuthApiService();

  static final MockUser _mockUser = MockUser(
    uid: IdGenerator.generateDriverId(),
    email: 'driver@rideshare.com',
    displayName: 'Driver User',
    photoURL: null,
  );

  MockUser? _localUser;
  late final StreamController<dynamic> _authStateController;

  AuthService() {
    _authStateController = StreamController<dynamic>.broadcast(
      onListen: () => _authStateController.add(currentUser),
    );
    // 1. Initialize local storage check
    _initializeLocalAuth();

    // 2. Listen for future Firebase changes
    auth.authStateChanges().listen((user) {
      _authStateController.add(user ?? _localUser);
    });
  }

  Future<void> _initializeLocalAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userData = prefs.getString('user_data');

      if (token != null && userData != null) {
        final data = json.decode(userData);
        _localUser = MockUser(
          uid: data['id'] ?? data['_id'] ?? data['uid'] ?? '',
          email: data['email'],
          displayName: data['name'],
        );
        // Only broadcast if Firebase hasn't already found a user
        if (auth.currentUser == null) {
          _authStateController.add(_localUser);
        }
      } else if (auth.currentUser == null) {
        _authStateController.add(null);
      }
    } catch (e) {
      debugPrint('Error initializing local auth: $e');
      if (auth.currentUser == null) _authStateController.add(null);
    }
  }

  FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    // Enable reCAPTCHA bypass for testing in debug mode on Web
    if (kIsWeb && kDebugMode) {
      _auth!.setSettings(appVerificationDisabledForTesting: true);
    }
    return _auth!;
  }

  dynamic get currentUser {
    if (kDemoMode) return _mockUser;
    // Prefer Firebase user if available, otherwise return local custom user
    return auth.currentUser ?? _localUser;
  }

  Stream<dynamic> get authStateChanges =>
      _authStateController.stream.distinct((prev, next) {
        // Basic comparison to prevent flickering
        if (prev == null && next == null) return true;
        if (prev != null && next != null) {
          final prevId = (prev is User) ? prev.uid : (prev as MockUser).uid;
          final nextId = (next is User) ? next.uid : (next as MockUser).uid;
          return prevId == nextId;
        }
        return false;
      });

  Future<String?> getIdToken() async {
    if (kDemoMode) return 'demo-token-for-testing';

    // 1. Check SharedPreferences first for local JWT (custom login)
    final prefs = await SharedPreferences.getInstance();
    final localToken = prefs.getString('auth_token');
    if (localToken != null && localToken.isNotEmpty) {
      return localToken;
    }

    // 2. Fallback to Firebase
    final user = auth.currentUser;
    if (user != null) {
      try {
        return await user.getIdToken().timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[AUTH] Firebase token timeout, returning null: $e');
        return null;
      }
    }
    return null;
  }

  // Save login state
  Future<void> _persistLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', isLoggedIn);
  }

  // ─── Google Sign-In ────────────────────────────────────────────────────────
  /// Signs in with Google and returns the Firebase [UserCredential].
  /// Works regardless of [kDemoMode] since it always opens a real OAuth flow.
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    if (googleAuth.idToken == null && googleAuth.accessToken == null) {
      throw Exception('Failed to obtain Google authentication tokens.');
    }

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential cred = await auth.signInWithCredential(credential);
    await _persistLoginState(true);
    return cred;
  }

  // ─── Facebook Sign-In ──────────────────────────────────────────────────────
  Future<UserCredential> signInWithFacebook() async {
    // Step 1 - Trigger Facebook login
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.success) {
      if (result.accessToken == null) {
        throw Exception('Facebook access token is null.');
      }

      // Create a Firebase credential
      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      // Sign into Firebase
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      await _persistLoginState(true);
      return cred;
    } else if (result.status == LoginStatus.cancelled) {
      throw Exception('Facebook login was cancelled by the user.');
    } else {
      throw Exception('Facebook login failed: ${result.message}');
    }
  }

  // ─── Phone OTP Authentication ──────────────────────────────────────────────
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    if (kDemoMode) {
      await Future.delayed(const Duration(seconds: 1));
      onCodeSent('demo-verification-id', null);
      return;
    }
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
    );
  }

  Future<dynamic> signInWithPhoneCredential(
    String verificationId,
    String smsCode,
  ) async {
    if (kDemoMode) {
      if (smsCode.length == 6) {
        await _persistLoginState(true);
        return _mockUser;
      }
      throw Exception('Invalid OTP');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final cred = await auth.signInWithCredential(credential);
    await _persistLoginState(true);
    return cred;
  }

  // Sign in with any credential (used for auto-verification)
  Future<dynamic> signInWithCredential(AuthCredential credential) async {
    final cred = await auth.signInWithCredential(credential);
    await _persistLoginState(true);
    return cred;
  }

  // ─── Email / Password Authentication ──────────────────────────────────────
  Future<dynamic> signInWithEmail(String email, String password) async {
    if (kDemoMode) {
      await Future.delayed(const Duration(seconds: 1));
      await _persistLoginState(true);
      return _mockUser;
    }
    final cred = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _persistLoginState(true);
    return cred;
  }

  Future<dynamic> signUpWithEmail(String email, String password) async {
    if (kDemoMode) {
      await _persistLoginState(true);
      return _mockUser;
    }
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _persistLoginState(true);
    return cred;
  }

  // ─── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[AUTH] Google signOut skipped: $e');
    }

    try {
      await FacebookAuth.instance.logOut();
    } on MissingPluginException catch (e) {
      // Keep logout working even if Facebook plugin isn't registered at runtime.
      debugPrint('[AUTH] Facebook signOut plugin missing: $e');
    } catch (e) {
      debugPrint('[AUTH] Facebook signOut skipped: $e');
    }

    try {
      if (!kDemoMode) {
        await auth.signOut();
      }
    } catch (e) {
      debugPrint('[AUTH] Firebase signOut skipped: $e');
    }

    await _persistLoginState(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    _localUser = null;
    _authStateController.add(null);
  }

  Future<void> resetPassword(String email) async {
    if (!kDemoMode) {
      await auth.sendPasswordResetEmail(email: email);
    }
  }

  // Check if session exists in local storage
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // ─── Custom Backend Auth ──────────────────────────────────────────────────
  Future<void> _applyCustomAuthSession(Map<String, dynamic> response) async {
    await _persistLoginState(true);
    final prefs = await SharedPreferences.getInstance();
    final token = (response['token'] ?? '').toString();
    if (token.isNotEmpty) {
      await prefs.setString('auth_token', token);
    }

    final userData = (response['user'] as Map<String, dynamic>? ?? <String, dynamic>{});
    await prefs.setString('user_data', json.encode(userData));
    _localUser = MockUser(
      uid: (userData['id'] ?? userData['_id'] ?? userData['uid'] ?? '').toString(),
      email: userData['email']?.toString(),
      displayName: userData['name']?.toString(),
    );
    _authStateController.add(_localUser);
  }

  Future<Map<String, dynamic>> signUpCustom({
    required String name,
    required String email,
    required String password,
    required String aadharCard,
    required String panCard,
  }) async {
    try {
      final token = await getIdToken();
      final response = await _authApi.signUpDriverWithEmail(
        name: name,
        email: email,
        password: password,
        aadharCard: aadharCard,
        panCard: panCard,
        bearerToken: token,
      );
      if (response['success']) {
        await _applyCustomAuthSession(response);
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signUpWithMobileCustom({
    required String name,
    required String mobileNumber,
    required String password,
  }) async {
    try {
      final response = await _authApi.signUpDriverWithMobile(
        name: name,
        mobileNumber: mobileNumber,
        password: password,
      );
      if (response['success']) {
        await _applyCustomAuthSession(response);
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signInCustom(String email, String password) async {
    try {
      final response = await _authApi.signInDriverWithEmail(
        email: email,
        password: password,
      );
      if (response['success']) {
        await _applyCustomAuthSession(response);
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signInWithMobileCustom({
    required String mobileNumber,
    required String password,
  }) async {
    try {
      final response = await _authApi.signInDriverWithMobile(
        mobileNumber: mobileNumber,
        password: password,
      );
      if (response['success']) {
        await _applyCustomAuthSession(response);
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signInWithGoogleCustom() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Google sign-in was cancelled.'};
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        return {'success': false, 'message': 'Google ID token not available.'};
      }

      final response = await _authApi.signInDriverWithGoogle(
        googleIdToken: idToken,
      );
      if (response['success']) {
        await _applyCustomAuthSession(response);
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

}
