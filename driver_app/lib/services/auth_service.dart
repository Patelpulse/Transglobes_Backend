import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/id_generator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


import 'database_service.dart';

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
  if (user == null) return false;
  final token = await authService.getIdToken();
  if (token == null) return false;
  return await dbService.isOnboardingComplete(user.uid, token);
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
    clientId: dotenv.env['GOOGLE_SIGN_IN_CLIENT_ID'],
  );

  static final MockUser _mockUser = MockUser(
    uid: IdGenerator.generateDriverId(),
    email: 'driver@rideshare.com',
    displayName: 'Driver User',
    photoURL: null,
  );

  FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    // Enable reCAPTCHA bypass for testing in debug mode on Web
    if (kIsWeb && kDebugMode) {
      _auth!.setSettings(appVerificationDisabledForTesting: true);
    }
    return _auth!;
  }

  dynamic get currentUser => kDemoMode ? _mockUser : auth.currentUser;

  Stream<dynamic> get authStateChanges =>
      kDemoMode ? Stream.value(_mockUser) : auth.authStateChanges();

  Future<String?> getIdToken() async {
    if (kDemoMode) return 'demo-token-for-testing';
    
    // Check local storage first for a cached token if needed, 
    // but Firebase already does this. We'll ensure it's available.
    final user = auth.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) {
        // Optionally save to local storage for quick access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
      }
      return token;
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
    // Step 1 – trigger the account-selection dialog
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled by the user.');
    }

    // Step 2 – obtain auth details
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Step 3 – create a Firebase credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Step 4 – sign into Firebase with the credential
    final cred = await FirebaseAuth.instance.signInWithCredential(credential);
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
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
    await _persistLoginState(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    if (!kDemoMode) {
      await auth.signOut();
    }
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
  Future<Map<String, dynamic>> signUpCustom({
    required String name,
    required String email,
    required String password,
    required String aadharCard,
    required String panCard,
  }) async {
    try {
      final response = await _signUpApi(name, email, password, aadharCard, panCard);
      if (response['success']) {
        await _persistLoginState(true);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token'] ?? '');
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signInCustom(String email, String password) async {
    try {
      final response = await _signInApi(email, password);
      if (response['success']) {
        await _persistLoginState(true);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token']);
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _signUpApi(String name, String email, String password, String aadhar, String pan) async {
    final url = Uri.parse('${dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000'}/api/driver/register');
    final response = await _post(url, {
      'name': name,
      'email': email,
      'password': password,
      'aadharCard': aadhar,
      'panCard': pan,
    });
    return response;
  }

  Future<Map<String, dynamic>> _signInApi(String email, String password) async {
    final url = Uri.parse('${dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000'}/api/driver/login');
    final response = await _post(url, {
      'email': email,
      'password': password,
    });
    return response;
  }

  Future<Map<String, dynamic>> _post(Uri url, Map<String, dynamic> body) async {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    final data = json.decode(response.body);
    return {
      'success': response.statusCode == 200 || response.statusCode == 201,
      'message': data['message'],
      'token': data['token'],
      'user': data['driver'] ?? data['user'],
    };
  }
}


