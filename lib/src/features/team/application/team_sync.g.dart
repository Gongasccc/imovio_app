// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamSyncService)
final teamSyncServiceProvider = TeamSyncServiceProvider._();

final class TeamSyncServiceProvider
    extends
        $FunctionalProvider<TeamSyncService, TeamSyncService, TeamSyncService>
    with $Provider<TeamSyncService> {
  TeamSyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamSyncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamSyncServiceHash();

  @$internal
  @override
  $ProviderElement<TeamSyncService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeamSyncService create(Ref ref) {
    return teamSyncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamSyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamSyncService>(value),
    );
  }
}

String _$teamSyncServiceHash() => r'd5f2df686cbb37e8120382b484b2e530630e320b';

/// Mantém a equipa a par dos imóveis do utilizador: sempre que um imóvel é
/// criado ou alterado, atualiza a cópia partilhada e os números de venda que
/// o padrinho vê. Fica ativo enquanto houver sessão iniciada (ver app.dart).

@ProviderFor(teamSync)
final teamSyncProvider = TeamSyncProvider._();

/// Mantém a equipa a par dos imóveis do utilizador: sempre que um imóvel é
/// criado ou alterado, atualiza a cópia partilhada e os números de venda que
/// o padrinho vê. Fica ativo enquanto houver sessão iniciada (ver app.dart).

final class TeamSyncProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Mantém a equipa a par dos imóveis do utilizador: sempre que um imóvel é
  /// criado ou alterado, atualiza a cópia partilhada e os números de venda que
  /// o padrinho vê. Fica ativo enquanto houver sessão iniciada (ver app.dart).
  TeamSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamSyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamSyncHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return teamSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$teamSyncHash() => r'104b92882da45d84e56f96f6a5ea374df93cd6a5';
