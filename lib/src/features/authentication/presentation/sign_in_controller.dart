import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';
import 'package:imovio/src/features/settings/domain/user_settings.dart';

part 'sign_in_controller.g.dart';

enum AuthMode { login, register, reset }

/// Estado do ecrã de entrada: `data(null)` em repouso, `data(mensagem)`
/// quando o email de recuperação foi enviado.
@riverpod
class SignInController extends _$SignInController {
  @override
  FutureOr<String?> build() => null;

  Future<void> submit({
    required AuthMode mode,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final auth = ref.read(authRepositoryProvider);
    try {
      switch (mode) {
        case AuthMode.reset:
          await auth.sendPasswordReset(email);
          state = const AsyncData(
            'Email enviado! Verifique a sua caixa de entrada.',
          );
        case AuthMode.login:
          await auth.signIn(email: email, password: password);
          if (ref.mounted) state = const AsyncData(null);
        case AuthMode.register:
          final credential =
              await auth.register(email: email, password: password);
          await ref.read(settingsRepositoryProvider).setSettings(
                uid: credential.user!.uid,
                settings: const UserSettings(theme: AppThemeChoice.dark),
              );
          if (ref.mounted) state = const AsyncData(null);
      }
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(friendlyAuthError(e), st);
    }
  }
}
