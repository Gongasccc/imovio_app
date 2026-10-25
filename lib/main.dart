import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imovio/firebase_options.dart';
import 'package:imovio/src/app.dart';
import 'package:imovio/src/features/settings/data/local_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_PT';
  await initializeDateFormatting('pt_PT');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Sessão guardada no dispositivo: só termina com "Terminar Sessão".
  if (kIsWeb) await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  // Cache local dos dados: a app abre com a última informação mesmo sem rede.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  // Espera que o Firebase reponha a sessão antes de decidir a primeira rota,
  // para não mostrar o login a quem já está ligado.
  await FirebaseAuth.instance.authStateChanges().first;
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const MyApp(),
  ));
}
