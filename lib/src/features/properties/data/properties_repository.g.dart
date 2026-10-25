// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'properties_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(firebaseStorage)
final firebaseStorageProvider = FirebaseStorageProvider._();

final class FirebaseStorageProvider
    extends
        $FunctionalProvider<FirebaseStorage, FirebaseStorage, FirebaseStorage>
    with $Provider<FirebaseStorage> {
  FirebaseStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseStorageHash();

  @$internal
  @override
  $ProviderElement<FirebaseStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseStorage create(Ref ref) {
    return firebaseStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseStorage>(value),
    );
  }
}

String _$firebaseStorageHash() => r'4d34fbbd82ac849c74805e19a05079afa5e20cad';

@ProviderFor(propertiesRepository)
final propertiesRepositoryProvider = PropertiesRepositoryProvider._();

final class PropertiesRepositoryProvider
    extends
        $FunctionalProvider<
          PropertiesRepository,
          PropertiesRepository,
          PropertiesRepository
        >
    with $Provider<PropertiesRepository> {
  PropertiesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'propertiesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$propertiesRepositoryHash();

  @$internal
  @override
  $ProviderElement<PropertiesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PropertiesRepository create(Ref ref) {
    return propertiesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PropertiesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PropertiesRepository>(value),
    );
  }
}

String _$propertiesRepositoryHash() =>
    r'7067ef1660c873c58f64bd7d33bc4f7bf88a9fec';

@ProviderFor(propertiesStream)
final propertiesStreamProvider = PropertiesStreamProvider._();

final class PropertiesStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Property>>,
          List<Property>,
          Stream<List<Property>>
        >
    with $FutureModifier<List<Property>>, $StreamProvider<List<Property>> {
  PropertiesStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'propertiesStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$propertiesStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Property>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Property>> create(Ref ref) {
    return propertiesStream(ref);
  }
}

String _$propertiesStreamHash() => r'fe4abc7666d4d463e3663e08315f90f1e52c437a';

@ProviderFor(propertyStream)
final propertyStreamProvider = PropertyStreamFamily._();

final class PropertyStreamProvider
    extends
        $FunctionalProvider<AsyncValue<Property?>, Property?, Stream<Property?>>
    with $FutureModifier<Property?>, $StreamProvider<Property?> {
  PropertyStreamProvider._({
    required PropertyStreamFamily super.from,
    required PropertyID super.argument,
  }) : super(
         retry: null,
         name: r'propertyStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$propertyStreamHash();

  @override
  String toString() {
    return r'propertyStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Property?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Property?> create(Ref ref) {
    final argument = this.argument as PropertyID;
    return propertyStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PropertyStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$propertyStreamHash() => r'b8962d5f44c85b3dc5d800e070dcc5b0bf868b1e';

final class PropertyStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Property?>, PropertyID> {
  PropertyStreamFamily._()
    : super(
        retry: null,
        name: r'propertyStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PropertyStreamProvider call(PropertyID id) =>
      PropertyStreamProvider._(argument: id, from: this);

  @override
  String toString() => r'propertyStreamProvider';
}

@ProviderFor(propertiesById)
final propertiesByIdProvider = PropertiesByIdProvider._();

final class PropertiesByIdProvider
    extends
        $FunctionalProvider<
          Map<PropertyID, Property>,
          Map<PropertyID, Property>,
          Map<PropertyID, Property>
        >
    with $Provider<Map<PropertyID, Property>> {
  PropertiesByIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'propertiesByIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$propertiesByIdHash();

  @$internal
  @override
  $ProviderElement<Map<PropertyID, Property>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<PropertyID, Property> create(Ref ref) {
    return propertiesById(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<PropertyID, Property> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<PropertyID, Property>>(value),
    );
  }
}

String _$propertiesByIdHash() => r'8ba6b1356c8e8cf18465ab349de606dd4ed371eb';
