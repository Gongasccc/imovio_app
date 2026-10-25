import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/constants/app_theme.dart';
import 'package:imovio/src/features/authentication/presentation/sign_in_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _mode = AuthMode.login;
  var _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setMode(AuthMode mode) {
    setState(() => _mode = mode);
    ref.invalidate(signInControllerProvider);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(signInControllerProvider.notifier).submit(
          mode: _mode,
          email: _email.text.trim(),
          password: _password.text,
        );
  }

  String get _submitLabel => switch (_mode) {
        AuthMode.login => 'Entrar na Conta',
        AuthMode.register => 'Registar Conta',
        AuthMode.reset => 'Enviar Email de Recuperação',
      };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Sizes.p16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(
                    MediaQuery.sizeOf(context).width < 480 ? Sizes.p20 : Sizes.p32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Logo(),
                      gapH8,
                      Text(
                        'O seu CRM imobiliário',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      gapH24,
                      SegmentedButton<AuthMode>(
                        segments: const [
                          ButtonSegment(
                              value: AuthMode.login, label: Text('Entrar')),
                          ButtonSegment(
                              value: AuthMode.register,
                              label: Text('Criar Conta')),
                          ButtonSegment(
                              value: AuthMode.reset, label: Text('Recuperar')),
                        ],
                        selected: {_mode},
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          textStyle: const TextStyle(fontSize: 12.5),
                        ),
                        onSelectionChanged: (s) => _setMode(s.first),
                      ),
                      gapH24,
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Introduza um email válido'
                            : null,
                      ),
                      if (_mode != AuthMode.reset) ...[
                        gapH16,
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Palavra-passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Mínimo de 6 caracteres'
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
                      if (_mode == AuthMode.login)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _setMode(AuthMode.reset),
                            child: const Text('Esqueceu-se da palavra-passe?'),
                          ),
                        ),
                      gapH16,
                      if (state.hasError)
                        _Message(
                          text: state.error.toString(),
                          color: scheme.error,
                        ),
                      if (!state.hasError && state.value != null)
                        _Message(text: state.value!, color: AppColors.green),
                      FilledButton(
                        onPressed: state.isLoading ? null : _submit,
                        child: state.isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_submitLabel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.home_work, color: AppColors.darkBg),
        ),
        gapW12,
        Text(
          'Imovio',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Sizes.p16),
      padding: const EdgeInsets.all(Sizes.p12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}
