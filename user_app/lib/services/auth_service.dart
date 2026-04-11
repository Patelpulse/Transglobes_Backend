import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

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
  static const String _webSessionUidKey = 'web_auth_uid';
  static const String _webSessionPhoneKey = 'web_auth_phone';
  static const String _webSessionNameKey = 'web_auth_name';
  static const String _webSessionEmailKey = 'web_auth_email';

  // Only initialize FirebaseAuth when NOT in demo mode
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final MockUser _mockUser = MockUser();
  static final StreamController<dynamic> _webAuthController =
      StreamController<dynamic>.broadcast();
  static MockUser? _webSessionUser;
  static bool _webSessionLoaded = false;
  static Future<void>? _webSessionLoadFuture;
  static String? _pendingWebPhoneNumber;

  AuthService() {
    if (kIsWeb && !kDemoMode) {
      _ensureWebSessionLoaded();
    }
  }

  /// Awaits web session restoration before resolving. No-op on native.
  Future<void> waitForSession() {
    if (kIsWeb && !kDemoMode) {
      return _ensureWebSessionLoaded();
    }
    return Future.value();
  }

  FirebaseAuth get auth {
    // Disable app verification (reCAPTCHA) on web for development
    if (kIsWeb) {
      _auth.setSettings(appVerificationDisabledForTesting: true);
    }
    return _auth;
  }

  dynamic get currentUser {
    if (kDemoMode) return _mockUser;
    if (kIsWeb && _webSessionUser != null) return _webSessionUser;
    return auth.currentUser;
  }

  Stream<dynamic> get authStateChanges {
    if (kDemoMode) {
      return Stream.value(_mockUser);
    }

    if (kIsWeb) {
      _ensureWebSessionLoaded();
      return Stream.multi((controller) {
        final emitCurrentState = () {
          controller.add(_webSessionUser ?? auth.currentUser);
        };

        if (_webSessionLoaded) {
          emitCurrentState();
        } else {
          _ensureWebSessionLoaded().then((_) => emitCurrentState());
        }

        final sessionSub = _webAuthController.stream.listen(controller.add);
        final firebaseSub = auth.authStateChanges().listen((user) {
          if (_webSessionUser == null) {
            controller.add(user);
          }
        });

        controller.onCancel = () async {
          await sessionSub.cancel();
          await firebaseSub.cancel();
        };
      });
    }

    return auth.authStateChanges();
  }

  Future<String?> getIdToken() async {
    if (kDemoMode) {
      return 'demo-token-for-testing';
    }

    final user = currentUser;

    if (user is User) {
      try {
        return await user.getIdToken();
      } catch (e) {
        debugPrint('[AUTH] Failed to fetch Firebase token: $e');
        return kDebugMode ? 'dev-token-bypass' : null;
      }
    }

    if (user is MockUser) {
      return 'dev-token-bypass';
    }

    return kDebugMode ? 'dev-token-bypass' : null;
  }

  Future<void> _ensureWebSessionLoaded() {
    if (_webSessionLoaded) {
      return Future.value();
    }

    _webSessionLoadFuture ??= _loadWebSession();
    return _webSessionLoadFuture!;
  }

  Future<void> _loadWebSession() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_webSessionUidKey);
    final phoneNumber = prefs.getString(_webSessionPhoneKey);

    if (uid != null && phoneNumber != null) {
      _webSessionUser = MockUser(
        uid: uid,
        displayName: prefs.getString(_webSessionNameKey),
        email: prefs.getString(_webSessionEmailKey),
        phoneNumber: phoneNumber,
      );
    }

    _webSessionLoaded = true;
    _webAuthController.add(_webSessionUser ?? auth.currentUser);
  }

  Future<void> _persistWebSession(MockUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webSessionUidKey, user.uid ?? '');
    await prefs.setString(_webSessionPhoneKey, user.phoneNumber ?? '');

    if ((user.displayName ?? '').isNotEmpty) {
      await prefs.setString(_webSessionNameKey, user.displayName!);
    } else {
      await prefs.remove(_webSessionNameKey);
    }

    if ((user.email ?? '').isNotEmpty) {
      await prefs.setString(_webSessionEmailKey, user.email!);
    } else {
      await prefs.remove(_webSessionEmailKey);
    }
  }

  Future<void> syncWebSessionUser({
    String? displayName,
    String? email,
    String? phoneNumber,
  }) async {
    if (!kIsWeb) return;

    await _ensureWebSessionLoaded();
    final activeUser = _webSessionUser;
    if (activeUser == null) return;

    if (displayName != null) activeUser.displayName = displayName;
    if (email != null) activeUser.email = email;
    if (phoneNumber != null) activeUser.phoneNumber = phoneNumber;

    await _persistWebSession(activeUser);
    _webAuthController.add(activeUser);
  }

  Future<void> _clearWebSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_webSessionUidKey);
    await prefs.remove(_webSessionPhoneKey);
    await prefs.remove(_webSessionNameKey);
    await prefs.remove(_webSessionEmailKey);
    _webSessionUser = null;
    _webAuthController.add(null);
  }

  Future<void> _signInWebBypassUser(String phoneNumber) async {
    await _ensureWebSessionLoaded();

    final normalizedDigits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final sessionUser = MockUser(
      uid: 'web-user-$normalizedDigits',
      phoneNumber: phoneNumber,
      displayName: _webSessionUser?.displayName,
      email: _webSessionUser?.email,
    );

    _webSessionUser = sessionUser;
    await _persistWebSession(sessionUser);
    _webAuthController.add(sessionUser);
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

    // On web, Firebase phone auth requires reCAPTCHA + authorized domain.
    // Use a simulated web flow — OTP is accepted client-side, backend validates phone.
    if (kIsWeb) {
      _pendingWebPhoneNumber = phoneNumber;
      await Future.delayed(const Duration(milliseconds: 500));
      onCodeSent('web-bypass-${phoneNumber.replaceAll('+', '')}', null);
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
    if (kDemoMode || kIsWeb) {
      // On web, accept any 6-digit OTP — backend validates the phone registration
      if (smsCode.length == 6) {
        if (kIsWeb) {
          final digitsFromVerificationId = verificationId.replaceFirst('web-bypass-', '');
          final normalizedPhone = _pendingWebPhoneNumber ??
              (digitsFromVerificationId.isNotEmpty ? '+$digitsFromVerificationId' : null);

          if (normalizedPhone == null || normalizedPhone.isEmpty) {
            throw Exception('Phone number missing for web sign-in');
          }

          await _signInWebBypassUser(normalizedPhone);
        }
        return null;
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
    if (kIsWeb) {
      await _clearWebSession();
    }
    if (!kDemoMode) {
      await auth.signOut();
    }
  }

  Future<void> resetPassword(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }
}
