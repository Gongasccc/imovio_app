import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'local_preferences.g.dart';

/// Preferências guardadas só neste dispositivo (último email usado, vista
/// escolhida nas tarefas). As preferências da conta vivem no Firestore.
class LocalPreferences {
  const LocalPreferences(this._prefs);
  final SharedPreferences _prefs;

  static const _lastEmailKey = 'lastEmail';
  static const _tasksCalendarKey = 'tasksCalendarView';

  String? get lastEmail => _prefs.getString(_lastEmailKey);
  Future<void> setLastEmail(String email) =>
      _prefs.setString(_lastEmailKey, email);

  bool get tasksCalendarView => _prefs.getBool(_tasksCalendarKey) ?? false;
  Future<void> setTasksCalendarView(bool value) =>
      _prefs.setBool(_tasksCalendarKey, value);
}

/// Substituído em `main` pela instância carregada antes de arrancar a app.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('sharedPreferencesProvider não foi inicializado');

@Riverpod(keepAlive: true)
LocalPreferences localPreferences(Ref ref) =>
    LocalPreferences(ref.watch(sharedPreferencesProvider));
