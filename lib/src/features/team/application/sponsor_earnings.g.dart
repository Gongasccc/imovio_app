// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sponsor_earnings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ganhos do utilizador com os afilhados que o indicaram como padrinho.

@ProviderFor(sponsorEarnings)
final sponsorEarningsProvider = SponsorEarningsProvider._();

/// Ganhos do utilizador com os afilhados que o indicaram como padrinho.

final class SponsorEarningsProvider
    extends
        $FunctionalProvider<
          SponsorEarnings?,
          SponsorEarnings?,
          SponsorEarnings?
        >
    with $Provider<SponsorEarnings?> {
  /// Ganhos do utilizador com os afilhados que o indicaram como padrinho.
  SponsorEarningsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sponsorEarningsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sponsorEarningsHash();

  @$internal
  @override
  $ProviderElement<SponsorEarnings?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SponsorEarnings? create(Ref ref) {
    return sponsorEarnings(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SponsorEarnings? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SponsorEarnings?>(value),
    );
  }
}

String _$sponsorEarningsHash() => r'6b9db4d4a7cb11e9f4df7ef2f695cc4194d5356f';
