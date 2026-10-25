// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_attachments_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contactAttachmentsRepository)
final contactAttachmentsRepositoryProvider =
    ContactAttachmentsRepositoryProvider._();

final class ContactAttachmentsRepositoryProvider
    extends
        $FunctionalProvider<
          ContactAttachmentsRepository,
          ContactAttachmentsRepository,
          ContactAttachmentsRepository
        >
    with $Provider<ContactAttachmentsRepository> {
  ContactAttachmentsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactAttachmentsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactAttachmentsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ContactAttachmentsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContactAttachmentsRepository create(Ref ref) {
    return contactAttachmentsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContactAttachmentsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContactAttachmentsRepository>(value),
    );
  }
}

String _$contactAttachmentsRepositoryHash() =>
    r'a0c2ca4e37c319c17915f69ae9d1f60861f12bd1';
