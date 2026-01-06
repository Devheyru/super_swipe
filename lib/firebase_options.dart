// Firebase configuration loaded from .env for security
// Run `flutter pub get` and ensure .env is in your project root with the required keys

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Values are loaded from .env file for security.
class DefaultFirebaseOptions {
  // Helper to get env values with fallback
  static String _env(String key, [String fallback = '']) =>
      dotenv.env[key] ?? fallback;

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
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _env('WEB_API_KEY'),
    appId: _env('WEB_APP_ID'),
    messagingSenderId: _env('WEB_MESSAGING_SENDER_ID'),
    projectId: _env('WEB_PROJECT_ID'),
    authDomain: _env('WEB_AUTH_DOMAIN'),
    storageBucket: _env('WEB_STORAGE_BUCKET'),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: _env('ANDROID_API_KEY'),
    appId: _env('ANDROID_APP_ID'),
    messagingSenderId: _env('ANDROID_MESSAGING_SENDER_ID'),
    projectId: _env('ANDROID_PROJECT_ID'),
    storageBucket: _env('ANDROID_STORAGE_BUCKET'),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: _env('IOS_API_KEY'),
    appId: _env('IOS_APP_ID'),
    messagingSenderId: _env('IOS_MESSAGING_SENDER_ID'),
    projectId: _env('IOS_PROJECT_ID'),
    storageBucket: _env('IOS_STORAGE_BUCKET'),
    iosBundleId: _env('IOS_BUNDLE_ID'),
    iosClientId: _env('IOS_CLIENT_ID'),
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: _env('IOS_API_KEY'),
    appId: _env('IOS_APP_ID'),
    messagingSenderId: _env('IOS_MESSAGING_SENDER_ID'),
    projectId: _env('IOS_PROJECT_ID'),
    storageBucket: _env('IOS_STORAGE_BUCKET'),
    iosBundleId: _env('IOS_BUNDLE_ID'),
    iosClientId: _env('IOS_CLIENT_ID'),
  );

  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: _env('ANDROID_API_KEY'),
    appId: _env('ANDROID_APP_ID'),
    messagingSenderId: _env('ANDROID_MESSAGING_SENDER_ID'),
    projectId: _env('ANDROID_PROJECT_ID'),
    storageBucket: _env('ANDROID_STORAGE_BUCKET'),
  );
}
