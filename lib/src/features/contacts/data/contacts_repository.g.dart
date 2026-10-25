// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contacts_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contactsRepository)
final contactsRepositoryProvider = ContactsRepositoryProvider._();

final class ContactsRepositoryProvider
    extends
        $FunctionalProvider<
          ContactsRepository,
          ContactsRepository,
          ContactsRepository
        >
    with $Provider<ContactsRepository> {
  ContactsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ContactsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContactsRepository create(Ref ref) {
    return contactsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContactsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContactsRepository>(value),
    );
  }
}

String _$contactsRepositoryHash() =>
    r'4b98bb6cdb5e0a10a29fe785a674b42dd96118b4';

@ProviderFor(contactsStream)
final contactsStreamProvider = ContactsStreamProvider._();

final class ContactsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Contact>>,
          List<Contact>,
          Stream<List<Contact>>
        >
    with $FutureModifier<List<Contact>>, $StreamProvider<List<Contact>> {
  ContactsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Contact>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Contact>> create(Ref ref) {
    return contactsStream(ref);
  }
}

String _$contactsStreamHash() => r'606fb3a3f152c50f7612f3094a2d46151f979080';

/// Contactos indexados por id, para mostrar nomes em negócios e tarefas.

@ProviderFor(contactsById)
final contactsByIdProvider = ContactsByIdProvider._();

/// Contactos indexados por id, para mostrar nomes em negócios e tarefas.

final class ContactsByIdProvider
    extends
        $FunctionalProvider<
          Map<ContactID, Contact>,
          Map<ContactID, Contact>,
          Map<ContactID, Contact>
        >
    with $Provider<Map<ContactID, Contact>> {
  /// Contactos indexados por id, para mostrar nomes em negócios e tarefas.
  ContactsByIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactsByIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactsByIdHash();

  @$internal
  @override
  $ProviderElement<Map<ContactID, Contact>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<ContactID, Contact> create(Ref ref) {
    return contactsById(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<ContactID, Contact> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<ContactID, Contact>>(value),
    );
  }
}

String _$contactsByIdHash() => r'42a43281b017d6daa6be955476ab5bc20c6e9113';
