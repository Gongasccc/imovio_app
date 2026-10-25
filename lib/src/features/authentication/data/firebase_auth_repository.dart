import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';

part 'firebase_auth_repository.g.dart';

class AuthRepository {
  AuthRepository(this._auth);
  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> register({
    required String email,
    required String password,
  }) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() => _auth.signOut();
}

/// Mensagens de erro em português, como na app original.
String friendlyAuthError(Object error) {
  final code = error is FirebaseAuthException ? error.code : '';
  switch (code) {
    case 'configuration-not-found':
      return 'O login por Email precisa de estar ativo no Firebase Console '
          '(Authentication > Sign-in method).';
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Email ou palavra-passe incorretos.';
    case 'email-already-in-use':
      return 'Este email já está registado.';
    case 'invalid-email':
      return 'O email não é válido.';
    case 'weak-password':
      return 'A palavra-passe deve ter pelo menos 6 caracteres.';
    case 'too-many-requests':
      return 'Demasiadas tentativas. Aguarde um pouco e tente novamente.';
    case 'network-request-failed':
      return 'Sem ligação à internet.';
    default:
      return 'Ocorreu um erro ao autenticar. Tente novamente.';
  }
}

@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(firebaseAuthProvider));

@Riverpod(keepAlive: true)
Stream<User?> authStateChanges(Ref ref) =>
    ref.watch(authRepositoryProvider).authStateChanges();

/// O uid do utilizador com sessão iniciada. Os ecrãs de dados só existem
/// depois do login (o router garante isso), por isso um uid nulo é um erro.
@Riverpod(keepAlive: true)
UserID currentUid(Ref ref) {
  final user = ref.watch(authStateChangesProvider).value ??
      ref.watch(authRepositoryProvider).currentUser;
  if (user == null) {
    throw StateError('Sem sessão iniciada');
  }
  return user.uid;
}
