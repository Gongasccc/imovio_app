import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/settings/domain/user_settings.dart';

part 'settings_repository.g.dart';

class SettingsRepository {
  const SettingsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static String settingsPath(UserID uid) => 'users/$uid/settings/config';

  Stream<UserSettings> watchSettings({required UserID uid}) => _firestore
      .doc(settingsPath(uid))
      .snapshots()
      .map((snapshot) => UserSettings.fromMap(snapshot.data()));

  Future<void> setSettings({
    required UserID uid,
    required UserSettings settings,
  }) =>
      _firestore
          .doc(settingsPath(uid))
          .set(settings.toMap(), SetOptions(merge: true));
}

@Riverpod(keepAlive: true)
FirebaseFirestore firestore(Ref ref) => FirebaseFirestore.instance;

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepository(ref.watch(firestoreProvider));

@riverpod
Stream<UserSettings> settingsStream(Ref ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(settingsRepositoryProvider).watchSettings(uid: uid);
}

/// Tema da app: escuro por omissão (também no ecrã de login), claro quando
/// o utilizador o escolheu nas configurações.
@riverpod
ThemeMode themeMode(Ref ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return ThemeMode.dark;
  final settings = ref.watch(settingsStreamProvider).value;
  return settings?.theme == AppThemeChoice.light
      ? ThemeMode.light
      : ThemeMode.dark;
}
