import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/id_generator.dart';

// Demo mode flag - set to false when you have real Firebase configured
// Google Sign-In always uses real Firebase (bypasses demo mode)
const bool kDemoMode = false;

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<dynamic>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
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
}
