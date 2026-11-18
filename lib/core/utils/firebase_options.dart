import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
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
        return linux;
      default:
        throw UnsupportedError(
          'Plataforma no soportada para las opciones de Firebase.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDf0yfjgaEfrYBe8OHcC8g2Gbj6pEG9e8c',
    appId: '1:723142799803:android:5b5418a98f3e1e909d549e',
    messagingSenderId: '723142799803',
    projectId: 'trendyvibe-410ea',
    storageBucket: 'trendyvibe-410ea.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDf0yfjgaEfrYBe8OHcC8g2Gbj6pEG9e8c',
    appId: '1:723142799803:android:5b5418a98f3e1e909d549e',
    messagingSenderId: '723142799803',
    projectId: 'trendyvibe-410ea',
    storageBucket: 'trendyvibe-410ea.firebasestorage.app',
    iosClientId: '',
    iosBundleId: '',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDf0yfjgaEfrYBe8OHcC8g2Gbj6pEG9e8c',
    appId: '1:723142799803:android:5b5418a98f3e1e909d549e',
    messagingSenderId: '723142799803',
    projectId: 'trendyvibe-410ea',
    storageBucket: 'trendyvibe-410ea.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDf0yfjgaEfrYBe8OHcC8g2Gbj6pEG9e8c',
    appId: '1:723142799803:android:5b5418a98f3e1e909d549e',
    messagingSenderId: '723142799803',
    projectId: 'trendyvibe-410ea',
    storageBucket: 'trendyvibe-410ea.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDf0yfjgaEfrYBe8OHcC8g2Gbj6pEG9e8c',
    appId: '1:723142799803:android:5b5418a98f3e1e909d549e',
    messagingSenderId: '723142799803',
    projectId: 'trendyvibe-410ea',
    storageBucket: 'trendyvibe-410ea.firebasestorage.app',
  );
}
