// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC-8K2RwJq6wOMkC7d0fB-So-SNNL6hv8w',
    appId: '1:698238504542:web:5eb6acfa6545a002c22ecf',
    messagingSenderId: '698238504542',
    projectId: 'farmwill-habits',
    authDomain: 'farmwill-habits.firebaseapp.com',
    databaseURL: 'https://farmwill-habits-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'farmwill-habits.firebasestorage.app',
    measurementId: 'G-5959TBZ9PH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDVO9fK12e08HCgQnox1I_T2LcYHDNRxak',
    appId: '1:698238504542:android:d4272a72e72d1ee1c22ecf',
    messagingSenderId: '698238504542',
    projectId: 'farmwill-habits',
    databaseURL: 'https://farmwill-habits-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'farmwill-habits.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD5hTtMw-vYEiDXQyFEZqdr3zf1ICpHFsM',
    appId: '1:698238504542:ios:34abf6e1edb4a8f7c22ecf',
    messagingSenderId: '698238504542',
    projectId: 'farmwill-habits',
    databaseURL: 'https://farmwill-habits-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'farmwill-habits.firebasestorage.app',
    iosBundleId: 'com.farmwill.habits',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD5hTtMw-vYEiDXQyFEZqdr3zf1ICpHFsM',
    appId: '1:698238504542:ios:34abf6e1edb4a8f7c22ecf',
    messagingSenderId: '698238504542',
    projectId: 'farmwill-habits',
    databaseURL: 'https://farmwill-habits-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'farmwill-habits.firebasestorage.app',
    iosBundleId: 'com.farmwill.habits',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC-8K2RwJq6wOMkC7d0fB-So-SNNL6hv8w',
    appId: '1:698238504542:web:31d5cdcdfefc0b3cc22ecf',
    messagingSenderId: '698238504542',
    projectId: 'farmwill-habits',
    authDomain: 'farmwill-habits.firebaseapp.com',
    databaseURL: 'https://farmwill-habits-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'farmwill-habits.firebasestorage.app',
    measurementId: 'G-LFRBNFN71Z',
  );
}
