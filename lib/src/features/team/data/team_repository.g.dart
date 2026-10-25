// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamRepository)
final teamRepositoryProvider = TeamRepositoryProvider._();

final class TeamRepositoryProvider
    extends $FunctionalProvider<TeamRepository, TeamRepository, TeamRepository>
    with $Provider<TeamRepository> {
  TeamRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamRepositoryHash();

  @$internal
  @override
  $ProviderElement<TeamRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeamRepository create(Ref ref) {
    return teamRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamRepository>(value),
    );
  }
}

String _$teamRepositoryHash() => r'b7511ef1dac2f6eb59e47d3fee56932d0f83104f';

@ProviderFor(membershipStream)
final membershipStreamProvider = MembershipStreamProvider._();

final class MembershipStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<Membership>,
          Membership,
          Stream<Membership>
        >
    with $FutureModifier<Membership>, $StreamProvider<Membership> {
  MembershipStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'membershipStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$membershipStreamHash();

  @$internal
  @override
  $StreamProviderElement<Membership> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Membership> create(Ref ref) {
    return membershipStream(ref);
  }
}

String _$membershipStreamHash() => r'234ebd7868e5d3c6d14f73b7aba0680d9b46b7b5';

/// A equipa atual, ou null se o utilizador não pertence a nenhuma.

@ProviderFor(teamStream)
final teamStreamProvider = TeamStreamProvider._();

/// A equipa atual, ou null se o utilizador não pertence a nenhuma.

final class TeamStreamProvider
    extends $FunctionalProvider<AsyncValue<Team?>, Team?, Stream<Team?>>
    with $FutureModifier<Team?>, $StreamProvider<Team?> {
  /// A equipa atual, ou null se o utilizador não pertence a nenhuma.
  TeamStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamStreamHash();

  @$internal
  @override
  $StreamProviderElement<Team?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Team?> create(Ref ref) {
    return teamStream(ref);
  }
}

String _$teamStreamHash() => r'9d0b8c6279d8c72e034cb6344d81226c887e6401';

@ProviderFor(teamMembersStream)
final teamMembersStreamProvider = TeamMembersStreamProvider._();

final class TeamMembersStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeamMember>>,
          List<TeamMember>,
          Stream<List<TeamMember>>
        >
    with $FutureModifier<List<TeamMember>>, $StreamProvider<List<TeamMember>> {
  TeamMembersStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamMembersStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamMembersStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<TeamMember>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TeamMember>> create(Ref ref) {
    return teamMembersStream(ref);
  }
}

String _$teamMembersStreamHash() => r'8fc7ec963ddf59fd84f0cd87a6e8e43f3848d89d';

/// Imóveis partilhados pelos outros membros (os próprios ficam de fora).

@ProviderFor(teamListingsStream)
final teamListingsStreamProvider = TeamListingsStreamProvider._();

/// Imóveis partilhados pelos outros membros (os próprios ficam de fora).

final class TeamListingsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeamListing>>,
          List<TeamListing>,
          Stream<List<TeamListing>>
        >
    with
        $FutureModifier<List<TeamListing>>,
        $StreamProvider<List<TeamListing>> {
  /// Imóveis partilhados pelos outros membros (os próprios ficam de fora).
  TeamListingsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamListingsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamListingsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<TeamListing>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TeamListing>> create(Ref ref) {
    return teamListingsStream(ref);
  }
}

String _$teamListingsStreamHash() =>
    r'cef7c51b327bb902ccfd387eea84347141c470c2';

@ProviderFor(sponsorSalesStream)
final sponsorSalesStreamProvider = SponsorSalesStreamProvider._();

final class SponsorSalesStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AfilhadoSale>>,
          List<AfilhadoSale>,
          Stream<List<AfilhadoSale>>
        >
    with
        $FutureModifier<List<AfilhadoSale>>,
        $StreamProvider<List<AfilhadoSale>> {
  SponsorSalesStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sponsorSalesStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sponsorSalesStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<AfilhadoSale>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AfilhadoSale>> create(Ref ref) {
    return sponsorSalesStream(ref);
  }
}

String _$sponsorSalesStreamHash() =>
    r'534655b2f26d2bdb050b3605ff19738f3752b29b';

@ProviderFor(afilhadoPctsStream)
final afilhadoPctsStreamProvider = AfilhadoPctsStreamProvider._();

final class AfilhadoPctsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<UserID, num>>,
          Map<UserID, num>,
          Stream<Map<UserID, num>>
        >
    with $FutureModifier<Map<UserID, num>>, $StreamProvider<Map<UserID, num>> {
  AfilhadoPctsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'afilhadoPctsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$afilhadoPctsStreamHash();

  @$internal
  @override
  $StreamProviderElement<Map<UserID, num>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<UserID, num>> create(Ref ref) {
    return afilhadoPctsStream(ref);
  }
}

String _$afilhadoPctsStreamHash() =>
    r'7f78c38856e0796960c8b144d3888956852d7fc3';
