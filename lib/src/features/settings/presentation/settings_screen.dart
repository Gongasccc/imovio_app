import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/common_widgets/form_fields.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';
import 'package:imovio/src/features/settings/domain/user_settings.dart';
import 'package:imovio/src/utils/dialogs.dart';
import 'package:imovio/src/utils/format.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = ref.watch(themeModeProvider) == ThemeMode.light;
    final email = ref.watch(authStateChangesProvider).value?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          ResponsiveCenter(
            maxContentWidth: 720,
            padding: const EdgeInsets.all(Sizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  title: 'Aparência',
                  icon: Icons.palette_outlined,
                  padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Modo claro'),
                    subtitle: const Text('Desligado usa o modo escuro'),
                    value: isLight,
                    onChanged: (value) {
                      final uid = ref.read(currentUidProvider);
                      ref
                          .read(settingsRepositoryProvider)
                          .setSettings(
                            uid: uid,
                            settings: UserSettings(
                              theme: value
                                  ? AppThemeChoice.light
                                  : AppThemeChoice.dark,
                            ),
                          );
                    },
                  ),
                ),
                gapH16,
                const SectionCard(
                  title: 'Comissões',
                  icon: Icons.percent,
                  child: _CommissionDefaults(),
                ),
                gapH16,
                const SectionCard(
                  title: 'Instalar no telemóvel',
                  icon: Icons.install_mobile_outlined,
                  child: Text(
                    'iPhone: abra a app no Safari, toque em Partilhar e '
                    'escolha "Adicionar ao ecrã principal".\n'
                    'Android: no Chrome, toque no menu ⋮ e escolha '
                    '"Instalar app".\n'
                    'A app abre em ecrã inteiro, com ícone próprio, e mantém '
                    'a sessão iniciada.',
                  ),
                ),
                gapH16,
                SectionCard(
                  title: 'Sessão',
                  icon: Icons.power_settings_new,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ligado como $email'),
                      gapH16,
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Terminar Sessão'),
                        onPressed: () async {
                          final ok = await showConfirmDialog(
                            context,
                            title: 'Terminar sessão',
                            message: 'Quer mesmo sair da sua conta?',
                            confirmLabel: 'Sair',
                          );
                          if (ok) {
                            await ref.read(authRepositoryProvider).signOut();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Percentagens usadas por omissão no resumo de venda de cada imóvel.
class _CommissionDefaults extends ConsumerStatefulWidget {
  const _CommissionDefaults();

  @override
  ConsumerState<_CommissionDefaults> createState() =>
      _CommissionDefaultsState();
}

class _CommissionDefaultsState extends ConsumerState<_CommissionDefaults> {
  TextEditingController? _commission;
  TextEditingController? _split;

  @override
  void dispose() {
    _commission?.dispose();
    _split?.dispose();
    super.dispose();
  }

  Future<void> _save(UserSettings current) async {
    final uid = ref.read(currentUidProvider);
    await ref
        .read(settingsRepositoryProvider)
        .setSettings(
          uid: uid,
          settings: current.copyWith(
            defaultCommissionPct: parseNum(_commission!.text),
            defaultAgentSplitPct: parseNum(_split!.text),
          ),
        );
    if (mounted) showSnack(context, 'Percentagens guardadas');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsStreamProvider).value;
    if (settings == null) return const LinearProgressIndicator();
    _commission ??= TextEditingController(text: '${settings.commissionPct}');
    _split ??= TextEditingController(text: '${settings.agentSplitPct}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Usadas no resumo de venda quando o imóvel não tem valores próprios.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        gapH16,
        FormGrid(
          children: [
            TextField(
              controller: _commission,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Comissão da agência (%)',
                helperText: 'Sobre o valor de venda',
                suffixText: '%',
              ),
            ),
            TextField(
              controller: _split,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'A sua parte da comissão (%)',
                helperText: 'O que fica para si dessa comissão',
                suffixText: '%',
              ),
            ),
          ],
        ),
        gapH16,
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => _save(settings),
            child: const Text('Guardar percentagens'),
          ),
        ),
      ],
    );
  }
}
