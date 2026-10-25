import 'package:equatable/equatable.dart';

enum AppThemeChoice {
  dark('dark'),
  light('light');

  const AppThemeChoice(this.value);
  final String value;

  static AppThemeChoice fromValue(Object? value) =>
      value == 'light' ? AppThemeChoice.light : AppThemeChoice.dark;
}

/// Documento `users/{uid}/settings/config`.
class UserSettings extends Equatable {
  const UserSettings({this.theme = AppThemeChoice.dark});
  final AppThemeChoice theme;

  factory UserSettings.fromMap(Map<String, dynamic>? data) =>
      UserSettings(theme: AppThemeChoice.fromValue(data?['theme']));

  Map<String, dynamic> toMap() => {'theme': theme.value};

  @override
  List<Object?> get props => [theme];
}
