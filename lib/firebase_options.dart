import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBjHEvpL4KK4n3NeCjgK12VoQIn0AZfvQA',
    appId: '1:1038306626235:web:7d054a950319db8fd3b79e',
    messagingSenderId: '1038306626235',
    projectId: 'bachat-gat-app-9e38e',
    authDomain: 'bachat-gat-app-9e38e.firebaseapp.com',
    storageBucket: 'bachat-gat-app-9e38e.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBjHEvpL4KK4n3NeCjgK12VoQIn0AZfvQA',
    appId: '1:1038306626235:android:7d054a950319db8fd3b79e',
    messagingSenderId: '1038306626235',
    projectId: 'bachat-gat-app-9e38e',
    storageBucket: 'bachat-gat-app-9e38e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBjHEvpL4KK4n3NeCjgK12VoQIn0AZfvQA',
    appId: '1:1038306626235:ios:7d054a950319db8fd3b79e',
    messagingSenderId: '1038306626235',
    projectId: 'bachat-gat-app-9e38e',
    storageBucket: 'bachat-gat-app-9e38e.firebasestorage.app',
  );
}
