// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_preferences.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Substituído em `main` pela instância carregada antes de arrancar a app.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Substituído em `main` pela instância carregada antes de arrancar a app.

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferences,
          SharedPreferences,
          SharedPreferences
        >
    with $Provider<SharedPreferences> {
  /// Substituído em `main` pela instância carregada antes de arrancar a app.
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'a5d29b184bd4a76d1fd95b1bbf9caae7c8eeb86e';

@ProviderFor(localPreferences)
final localPreferencesProvider = LocalPreferencesProvider._();

final class LocalPreferencesProvider
    extends
        $FunctionalProvider<
          LocalPreferences,
          LocalPreferences,
          LocalPreferences
        >
    with $Provider<LocalPreferences> {
  LocalPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localPreferencesHash();

  @$internal
  @override
  $ProviderElement<LocalPreferences> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalPreferences create(Ref ref) {
    return localPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalPreferences>(value),
    );
  }
}

String _$localPreferencesHash() => r'6b4a1eeb63664770d65f39354d6b33d5a9e46dd1';
