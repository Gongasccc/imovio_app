// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Estado do ecrã de entrada: `data(null)` em repouso, `data(mensagem)`
/// quando o email de recuperação foi enviado.

@ProviderFor(SignInController)
final signInControllerProvider = SignInControllerProvider._();

/// Estado do ecrã de entrada: `data(null)` em repouso, `data(mensagem)`
/// quando o email de recuperação foi enviado.
final class SignInControllerProvider
    extends $AsyncNotifierProvider<SignInController, String?> {
  /// Estado do ecrã de entrada: `data(null)` em repouso, `data(mensagem)`
  /// quando o email de recuperação foi enviado.
  SignInControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInControllerHash();

  @$internal
  @override
  SignInController create() => SignInController();
}

String _$signInControllerHash() => r'ff8869c128d8450f8a74a2e9440e2d04b9468474';

/// Estado do ecrã de entrada: `data(null)` em repouso, `data(mensagem)`
/// quando o email de recuperação foi enviado.

abstract class _$SignInController extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
