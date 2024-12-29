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
    apiKey: 'AIzaSyB9i4CgvcwQUhVeHllxcywwdwLpo92hsYQ',
    appId: '1:662430635566:web:f8d70eef8613d9095771bf',
    messagingSenderId: '662430635566',
    projectId: 'aac-app-24',
    authDomain: 'aac-app-24.firebaseapp.com',
    databaseURL: 'https://aac-app-24-default-rtdb.firebaseio.com',
    storageBucket: 'aac-app-24.appspot.com',
    measurementId: 'G-CXZH7RGKEX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCdbQv3GYIjQ1IXsyz2Hfgff0vrc21ZlOw',
    appId: '1:662430635566:android:114537d11282fad95771bf',
    messagingSenderId: '662430635566',
    projectId: 'aac-app-24',
    databaseURL: 'https://aac-app-24-default-rtdb.firebaseio.com',
    storageBucket: 'aac-app-24.appspot.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB9i4CgvcwQUhVeHllxcywwdwLpo92hsYQ',
    appId: '1:662430635566:web:881465cbb0b19ab35771bf',
    messagingSenderId: '662430635566',
    projectId: 'aac-app-24',
    authDomain: 'aac-app-24.firebaseapp.com',
    databaseURL: 'https://aac-app-24-default-rtdb.firebaseio.com',
    storageBucket: 'aac-app-24.appspot.com',
    measurementId: 'G-QJ0X1ZPL0D',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBPY7ngSGol9gA65rqMRtHHt7fels1Yt7E',
    appId: '1:662430635566:ios:88701b6210ca0e865771bf',
    messagingSenderId: '662430635566',
    projectId: 'aac-app-24',
    databaseURL: 'https://aac-app-24-default-rtdb.firebaseio.com',
    storageBucket: 'aac-app-24.appspot.com',
    iosBundleId: 'com.example.mindbridgeBetaMain',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBPY7ngSGol9gA65rqMRtHHt7fels1Yt7E',
    appId: '1:662430635566:ios:88701b6210ca0e865771bf',
    messagingSenderId: '662430635566',
    projectId: 'aac-app-24',
    databaseURL: 'https://aac-app-24-default-rtdb.firebaseio.com',
    storageBucket: 'aac-app-24.appspot.com',
    iosBundleId: 'com.example.mindbridgeBetaMain',
  );
}
