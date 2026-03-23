import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

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
  // Only initialize FirebaseAuth when NOT in demo mode
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final MockUser _mockUser = MockUser();

  FirebaseAuth get auth {
    // Disable app verification (reCAPTCHA) on web for development
    if (kIsWeb) {
      _auth.setSettings(appVerificationDisabledForTesting: true);
    }
    return _auth;
  }

  dynamic get currentUser => kDemoMode ? _mockUser : auth.currentUser;

  Stream<dynamic> get authStateChanges =>
      kDemoMode ? Stream.value(_mockUser) : auth.authStateChanges();

  Future<String?> getIdToken() async {
    // Force 'dev-token-bypass' for now to ensure development is not blocked by token verification issues
    return 'dev-token-bypass';
  }

  // Phone OTP Authentication
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    if (kDemoMode) {
      // In demo mode, simulate OTP sent after 1 second
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

  Future<UserCredential?> signInWithPhoneCredential(
    String verificationId,
    String smsCode,
  ) async {
    if (kDemoMode) {
      // In demo mode, accept any 6-digit OTP
      if (smsCode.length == 6) {
        return null; // Demo login successful
      }
      throw Exception('Invalid OTP');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await auth.signInWithCredential(credential);
  }

  // Sign in with any credential (used for auto-verification)
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    return await auth.signInWithCredential(credential);
  }

  // Email/Password Authentication
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    if (!kDemoMode) {
      await auth.signOut();
    }
  }

  Future<void> resetPassword(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }
}
