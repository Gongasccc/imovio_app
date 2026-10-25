// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dashboardKpis)
final dashboardKpisProvider = DashboardKpisProvider._();

final class DashboardKpisProvider
    extends
        $FunctionalProvider<
          AsyncValue<DashboardKpis>,
          AsyncValue<DashboardKpis>,
          AsyncValue<DashboardKpis>
        >
    with $Provider<AsyncValue<DashboardKpis>> {
  DashboardKpisProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardKpisProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardKpisHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<DashboardKpis>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<DashboardKpis> create(Ref ref) {
    return dashboardKpis(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<DashboardKpis> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<DashboardKpis>>(value),
    );
  }
}

String _$dashboardKpisHash() => r'd19615a9c94020d767400e2958238a5038194e80';
