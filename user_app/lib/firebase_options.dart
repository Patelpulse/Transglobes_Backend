import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// IMPORTANT: Replace these placeholder values with your actual Firebase project credentials.
///
/// To get your Firebase configuration:
/// 1. Go to Firebase Console (https://console.firebase.google.com)
/// 2. Select your project
/// 3. Go to Project Settings > General
/// 4. Scroll down to "Your apps" section
/// 5. Add Web, Android, and iOS apps
/// 6. Copy the configuration values here
///
/// OR run: flutterfire configure
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Final Web Firebase Configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBcc-cYJ-xfLYwo8Jyc6eZmgk918j0WL28',
    appId: '1:1072284227316:web:f7c08816b810cc00cd30a1',
    messagingSenderId: '1072284227316',
    projectId: 'mera-ubar',
    authDomain: 'mera-ubar.firebaseapp.com',
    storageBucket: 'mera-ubar.firebasestorage.app',
    measurementId: 'G-1BETFQFRZV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBcc-cYJ-xfLYwo8Jyc6eZmgk918j0WL28',
    appId: '1:1072284227316:android:967e253fa09ff7e4cd30a1',
    messagingSenderId: '1072284227316',
    projectId: 'mera-ubar',
    storageBucket: 'mera-ubar.firebasestorage.app',
  );

  // TODO: Replace with your actual Firebase iOS configuration
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.userApp',
  );

  // TODO: Replace with your actual Firebase macOS configuration
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.userApp',
  );
}
