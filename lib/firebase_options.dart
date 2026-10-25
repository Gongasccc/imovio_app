// Configuração do Firebase para o projeto realestateapp-43e70.
//
// A configuração web foi copiada da app original (index.html).
// Para iOS, corre `flutterfire configure --project=realestateapp-43e70`
// num ambiente com a FlutterFire CLI: o comando regenera este ficheiro
// com a configuração iOS e cria o GoogleService-Info.plist.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Falta a configuração iOS do Firebase. Corre '
          '`flutterfire configure --project=realestateapp-43e70`.',
        );
      default:
        throw UnsupportedError(
          'Plataforma não suportada: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAwRpWCHA1NOHCpwFIA3rjG2K4OsbqPdPM',
    appId: '1:38289869794:web:e3a825ff720973197807bb',
    messagingSenderId: '38289869794',
    projectId: 'realestateapp-43e70',
    authDomain: 'realestateapp-43e70.firebaseapp.com',
    storageBucket: 'realestateapp-43e70.firebasestorage.app',
    measurementId: 'G-E34SZ3HJC3',
  );
}
