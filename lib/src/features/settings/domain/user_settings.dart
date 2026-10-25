import 'package:equatable/equatable.dart';
import 'package:imovio/src/utils/format.dart';

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
  const UserSettings({
    this.theme = AppThemeChoice.dark,
    this.defaultCommissionPct,
    this.defaultAgentSplitPct,
  });

  final AppThemeChoice theme;

  /// Comissão da agência sugerida para imóveis novos (% do valor de venda).
  final num? defaultCommissionPct;

  /// A sua parte da comissão sugerida para imóveis novos (%).
  final num? defaultAgentSplitPct;

  static const fallbackCommissionPct = 5;
  static const fallbackAgentSplitPct = 50;

  num get commissionPct => defaultCommissionPct ?? fallbackCommissionPct;
  num get agentSplitPct => defaultAgentSplitPct ?? fallbackAgentSplitPct;

  factory UserSettings.fromMap(Map<String, dynamic>? data) => UserSettings(
    theme: AppThemeChoice.fromValue(data?['theme']),
    defaultCommissionPct: parseNum(data?['defaultCommissionPct']),
    defaultAgentSplitPct: parseNum(data?['defaultAgentSplitPct']),
  );

  /// Só escreve os campos definidos; o repositório faz merge.
  Map<String, dynamic> toMap() => {
    'theme': theme.value,
    'defaultCommissionPct': ?defaultCommissionPct,
    'defaultAgentSplitPct': ?defaultAgentSplitPct,
  };

  UserSettings copyWith({
    AppThemeChoice? theme,
    num? defaultCommissionPct,
    num? defaultAgentSplitPct,
  }) => UserSettings(
    theme: theme ?? this.theme,
    defaultCommissionPct: defaultCommissionPct ?? this.defaultCommissionPct,
    defaultAgentSplitPct: defaultAgentSplitPct ?? this.defaultAgentSplitPct,
  );

  @override
  List<Object?> get props => [
    theme,
    defaultCommissionPct,
    defaultAgentSplitPct,
  ];
}
