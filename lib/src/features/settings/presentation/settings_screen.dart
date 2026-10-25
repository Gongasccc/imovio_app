import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';
import 'package:imovio/src/features/settings/domain/user_settings.dart';
import 'package:imovio/src/routing/app_router.dart';
import 'package:imovio/src/utils/dialogs.dart';

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
                SectionCard(
                  title: 'Equipa',
                  icon: Icons.groups_outlined,
                  padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Equipa e afilhados'),
                    subtitle: const Text(
                      'Partilhar imóveis com colegas e ver os ganhos dos '
                      'seus afilhados',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushNamed(AppRoute.team.name),
                  ),
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
