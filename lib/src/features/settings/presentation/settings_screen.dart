import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imovio/src/utils/file_saver.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/pipeline/data/deals_repository.dart';
import 'package:imovio/src/features/interactions/data/interactions_repository.dart';
import 'package:imovio/src/features/export/application/export_service.dart'
    deferred as backup;
import 'package:imovio/src/features/expenses/data/expenses_repository.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/features/ai/data/gemini_repository.dart';
import 'package:imovio/src/features/ai/presentation/gemini_key_dialog.dart';
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
                const _BackupCard(),
                gapH16,
                SectionCard(
                  title: 'Comunicação',
                  icon: Icons.forum_outlined,
                  padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.text_snippet_outlined),
                    title: const Text('Modelos de mensagens'),
                    subtitle: const Text(
                        'WhatsApp, SMS e email com os dados preenchidos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushNamed(AppRoute.templates.name),
                  ),
                ),
                gapH16,
                const _AiSettingsCard(),
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

/// Uma só chave Gemini para toda a app (estudo de mercado e importação de
/// anúncios). Fica guardada na conta, por isso vale em todos os dispositivos.
class _AiSettingsCard extends ConsumerWidget {
  const _AiSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = ref.watch(geminiKeyProvider).value;
    final hasKey = key != null && key.isNotEmpty;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SectionCard(
      title: 'Inteligência artificial (Gemini)',
      icon: Icons.auto_awesome_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasKey
                ? 'Chave configurada (termina em '
                    '${key.substring(key.length - 4)}). É usada em toda a app: '
                    'estudo de mercado e importação de anúncios por link.'
                : 'Sem chave. Com uma chave gratuita do Google AI Studio, o '
                    'Gemini pesquisa preços na zona para o estudo de mercado e '
                    'ajuda a ler os anúncios importados por link.',
            style: TextStyle(color: muted),
          ),
          gapH16,
          Wrap(
            spacing: Sizes.p8,
            runSpacing: Sizes.p8,
            children: [
              FilledButton.icon(
                icon: Icon(hasKey ? Icons.edit_outlined : Icons.key_outlined),
                label: Text(hasKey ? 'Alterar chave' : 'Configurar chave'),
                onPressed: () => showGeminiKeyDialog(context),
              ),
              if (hasKey)
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover chave'),
                  onPressed: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'Remover chave Gemini',
                      message: 'As funções com IA deixam de funcionar até '
                          'configurar uma chave nova.',
                      confirmLabel: 'Remover',
                    );
                    if (!ok) return;
                    await ref.read(geminiKeyRepositoryProvider).setKey(
                          uid: ref.read(currentUidProvider),
                          key: null,
                        );
                    if (context.mounted) showSnack(context, 'Chave removida');
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Exportar tudo para Excel (cópia de segurança).
class _BackupCard extends ConsumerWidget {
  const _BackupCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      title: 'Cópia de segurança',
      icon: Icons.backup_outlined,
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.grid_on_outlined),
        title: const Text('Exportar tudo para Excel'),
        subtitle: const Text(
            'Contactos, imóveis, negócios, tarefas, despesas e interações'),
        trailing: const Icon(Icons.download_outlined),
        onTap: () async {
          await backup.loadLibrary();
          if (!context.mounted) return;
          final bytes = backup.exportAllToXlsx(
            contacts: ref.read(contactsStreamProvider).value ?? const [],
            properties: ref.read(propertiesStreamProvider).value ?? const [],
            deals: ref.read(dealsStreamProvider).value ?? const [],
            tasks: ref.read(tasksStreamProvider).value ?? const [],
            expenses: ref.read(expensesStreamProvider).value ?? const [],
            interactions: ref.read(interactionsStreamProvider).value ?? const [],
          );
          final d = DateTime.now();
          final name = 'imovio-${d.year}-${d.month.toString().padLeft(2, '0')}'
              '-${d.day.toString().padLeft(2, '0')}.xlsx';
          final ok = saveBytesFile(
            fileName: name,
            bytes: bytes,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );
          showSnack(context,
              ok ? 'Excel descarregado: $name' : 'Exportação só disponível na versão web.');
        },
      ),
    );
  }
}
