import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imovio/src/common_widgets/async_value_widget.dart';
import 'package:imovio/src/common_widgets/empty_placeholder.dart';
import 'package:imovio/src/common_widgets/form_fields.dart';
import 'package:imovio/src/common_widgets/responsive_center.dart';
import 'package:imovio/src/common_widgets/section_card.dart';
import 'package:imovio/src/constants/app_sizes.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/properties/presentation/property_list_tile.dart';
import 'package:imovio/src/features/team/application/sponsor_earnings.dart';
import 'package:imovio/src/features/team/data/team_repository.dart';
import 'package:imovio/src/features/team/domain/team.dart';
import 'package:imovio/src/features/team/presentation/team_listing_tile.dart';
import 'package:imovio/src/utils/dialogs.dart';
import 'package:imovio/src/utils/format.dart';
import 'package:imovio/src/utils/run_action.dart';

/// Equipa: membros e padrinhos, imóveis partilhados e ganhos de afilhados.
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamStreamProvider);
    return AsyncValueWidget<Team?>(
      value: team,
      data: (team) => team == null
          ? Scaffold(
              appBar: AppBar(title: const Text('Equipa')),
              body: const _NoTeam(),
            )
          : DefaultTabController(
              length: 4,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(team.name),
                  bottom: const TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      Tab(text: 'Equipa'),
                      Tab(text: 'Imóveis da equipa'),
                      Tab(text: 'Afilhados'),
                      Tab(text: 'O que partilho'),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    _Padded(child: _MembersTab(team: team)),
                    const _Padded(child: _ListingsTab()),
                    const _Padded(child: _EarningsTab()),
                    const _Padded(child: _SharingTab()),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Padded extends StatelessWidget {
  const _Padded({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      ResponsiveCenter(
        maxContentWidth: 820,
        padding: const EdgeInsets.all(Sizes.p16),
        child: child,
      ),
    ],
  );
}

String? _required(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;

class _NoTeam extends ConsumerStatefulWidget {
  const _NoTeam();

  @override
  ConsumerState<_NoTeam> createState() => _NoTeamState();
}

class _NoTeamState extends ConsumerState<_NoTeam> {
  final _createKey = GlobalKey<FormState>();
  final _joinKey = GlobalKey<FormState>();
  final _teamName = TextEditingController();
  final _myName = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _teamName.dispose();
    _myName.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    await runAction(context, action, success: success);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(teamRepositoryProvider);
    final uid = ref.read(currentUidProvider);
    return _Padded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Numa equipa, os consultores veem os imóveis uns dos outros (sem '
            'proprietário, comissões nem notas) e esses imóveis aparecem nas '
            'sugestões dos seus clientes. Quem indica um padrinho envia-lhe os '
            'números das suas vendas, para ele calcular a sua percentagem.',
          ),
          gapH16,
          SectionCard(
            title: 'O seu nome na equipa',
            icon: Icons.badge_outlined,
            child: TextField(
              controller: _myName,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Como os colegas o veem',
              ),
            ),
          ),
          gapH16,
          SectionCard(
            title: 'Entrar numa equipa',
            icon: Icons.login,
            child: Form(
              key: _joinKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Código da equipa',
                      hintText: 'Ex.: K7M2QX',
                    ),
                    validator: _required,
                  ),
                  gapH16,
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _busy
                          ? null
                          : () {
                              if (!_joinKey.currentState!.validate()) return;
                              if (_myName.text.trim().isEmpty) {
                                showSnack(context, 'Indique o seu nome',
                                    error: true);
                                return;
                              }
                              _run(
                                () => repo.joinTeam(
                                  uid: uid,
                                  code: _code.text,
                                  myName: _myName.text.trim(),
                                ),
                                'Entrou na equipa. Escolha o seu padrinho.',
                              );
                            },
                      child: const Text('Entrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          gapH16,
          SectionCard(
            title: 'Criar uma equipa',
            icon: Icons.group_add_outlined,
            child: Form(
              key: _createKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _teamName,
                    decoration: const InputDecoration(
                      labelText: 'Nome da equipa',
                    ),
                    validator: _required,
                  ),
                  gapH16,
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: _busy
                          ? null
                          : () {
                              if (!_createKey.currentState!.validate()) return;
                              if (_myName.text.trim().isEmpty) {
                                showSnack(context, 'Indique o seu nome',
                                    error: true);
                                return;
                              }
                              _run(
                                () => repo.createTeam(
                                  uid: uid,
                                  teamName: _teamName.text.trim(),
                                  myName: _myName.text.trim(),
                                ),
                                'Equipa criada',
                              );
                            },
                      child: const Text('Criar equipa'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.team});
  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    final members = ref.watch(teamMembersStreamProvider).value ?? const [];
    final byUid = {for (final m in members) m.uid: m};
    final me = byUid[uid];
    final repo = ref.read(teamRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Convidar',
          icon: Icons.qr_code_2,
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  team.code,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copiar código',
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: team.code));
                  showSnack(context, 'Código copiado');
                },
              ),
            ],
          ),
        ),
        gapH16,
        if (me != null)
          SectionCard(
            title: 'O meu padrinho',
            icon: Icons.handshake_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextDropdown(
                  label: 'Quem o trouxe para a empresa',
                  value: me.sponsorUid,
                  allowEmpty: true,
                  options: [
                    for (final m in members)
                      if (m.uid != uid) m.uid,
                  ],
                  optionLabels: {for (final m in members) m.uid: m.name},
                  onChanged: (v) => runAction(
                    context,
                    () => repo.setSponsor(
                      teamId: team.id,
                      uid: uid,
                      sponsorUid: v,
                    ),
                    success: 'Padrinho guardado',
                  ),
                ),
                gapH8,
                Text(
                  'O padrinho vê o estado, o valor e a sua parte da comissão '
                  'de cada imóvel seu, para calcular a percentagem dele. Não vê '
                  'proprietários, contactos nem notas.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        gapH16,
        _TeamAiKeyCard(team: team, isOwner: team.ownerUid == uid),
        gapH16,
        SectionCard(
          title: 'Membros (${members.length})',
          icon: Icons.groups_outlined,
          child: Column(
            children: [
              for (final m in members)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(
                    m.uid == uid ? '${m.name} (eu)' : m.name,
                  ),
                  subtitle: m.sponsorUid == null
                      ? null
                      : Text(
                          'Afilhado de ${byUid[m.sponsorUid]?.name ?? '—'}',
                        ),
                  trailing: m.uid == team.ownerUid
                      ? const Chip(label: Text('Criador'))
                      : null,
                ),
            ],
          ),
        ),
        gapH16,
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Sair da equipa'),
            onPressed: () async {
              final ok = await showConfirmDialog(
                context,
                title: 'Sair da equipa',
                message:
                    'Os seus imóveis deixam de estar partilhados e o seu '
                    'padrinho deixa de ver as suas vendas.',
                confirmLabel: 'Sair',
              );
              if (ok && context.mounted) {
                await runAction(
                  context,
                  () => repo.leaveTeam(teamId: team.id, uid: uid),
                  success: 'Saiu da equipa',
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ListingsTab extends ConsumerWidget {
  const _ListingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(teamListingsStreamProvider).value ?? const [];
    if (listings.isEmpty) {
      return const EmptyPlaceholder(
        icon: Icons.home_work_outlined,
        message: 'Os colegas ainda não partilharam imóveis.',
      );
    }
    final sorted = [...listings]
      ..sort((a, b) => a.agentName.compareTo(b.agentName));
    return SectionCard(
      child: Column(
        children: [for (final l in sorted) TeamListingTile(listing: l)],
      ),
    );
  }
}

class _EarningsTab extends ConsumerWidget {
  const _EarningsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(sponsorEarningsProvider);
    if (earnings == null) return const LinearProgressIndicator();
    if (earnings.afilhados.isEmpty) {
      return const EmptyPlaceholder(
        icon: Icons.handshake_outlined,
        message:
            'Ainda ninguém o indicou como padrinho. Cada afilhado escolhe o '
            'padrinho no separador Equipa.',
      );
    }
    Widget stat(String label, num value) => Expanded(
      child: Column(
        children: [
          Text(
            Format.eurosWithCents(value),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Os meus ganhos de afilhados',
          icon: Icons.euro,
          child: Row(
            children: [
              stat('Vendidos', earnings.realized),
              stat('Reservados / CPCV', earnings.forecast),
              stat('Em angariação', earnings.portfolio),
            ],
          ),
        ),
        for (final a in earnings.afilhados) ...[
          gapH16,
          SectionCard(
            title: a.afilhadoName,
            icon: Icons.person_outline,
            trailing: _PctField(afilhadoUid: a.afilhadoUid, pct: a.pct),
            child: a.sales.isEmpty
                ? const Text('Sem imóveis com preço.')
                : Column(
                    children: [
                      for (final s in a.sales)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.title),
                          subtitle: Text(
                            '${s.saleStatus ?? 'Sem estado'} · '
                            '${Format.euros(s.salePrice)} · parte '
                            '${Format.eurosWithCents(s.agentShare)}',
                          ),
                          trailing: Text(
                            Format.eurosWithCents(sponsorCut(s, a.pct)),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: s.isSold
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ],
    );
  }
}

/// A % do padrinho sobre a parte deste afilhado. Guarda ao sair do campo.
class _PctField extends ConsumerStatefulWidget {
  const _PctField({required this.afilhadoUid, required this.pct});
  final String afilhadoUid;
  final num? pct;

  @override
  ConsumerState<_PctField> createState() => _PctFieldState();
}

class _PctFieldState extends ConsumerState<_PctField> {
  late final _controller = TextEditingController(
    text: widget.pct == null ? '' : '${widget.pct}',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final pct = parseNum(_controller.text);
    if (pct == widget.pct) return;
    runAction(
      context,
      () => ref.read(teamRepositoryProvider).setAfilhadoPct(
        uid: ref.read(currentUidProvider),
        afilhadoUid: widget.afilhadoUid,
        pct: pct,
      ),
      success: 'Percentagem guardada',
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 110,
    child: Focus(
      onFocusChange: (focused) {
        if (!focused) _save();
      },
      child: TextField(
        controller: _controller,
        onSubmitted: (_) => _save(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'A minha %',
          suffixText: '%',
          isDense: true,
        ),
      ),
    ),
  );
}

class _SharingTab extends ConsumerWidget {
  const _SharingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(membershipStreamProvider).value;
    final properties = (ref.watch(propertiesStreamProvider).value ?? const [])
        .where((p) => !p.isSold)
        .toList();
    if (membership == null) return const LinearProgressIndicator();
    final hidden = membership.hiddenListings;
    return SectionCard(
      title: 'Imóveis que a equipa vê',
      icon: Icons.share_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Todos os imóveis ativos são partilhados, exceto os que desligar '
            'aqui. Os vendidos deixam de ser partilhados.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          gapH8,
          for (final p in properties)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: PropertyImage(url: p.cover, width: 56, height: 42),
              ),
              title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${p.tags} · ${Format.euros(p.price)}'),
              value: !hidden.contains(p.id),
              onChanged: (share) => ref
                  .read(teamRepositoryProvider)
                  .setHiddenListings(
                    uid: ref.read(currentUidProvider),
                    hidden: share
                        ? hidden.where((id) => id != p.id).toList()
                        : [...hidden, p.id],
                  ),
            ),
        ],
      ),
    );
  }
}

/// Chave do Gemini da equipa: o criador põe-na uma vez e quem não tem chave
/// própria passa a usá-la.
class _TeamAiKeyCard extends ConsumerStatefulWidget {
  const _TeamAiKeyCard({required this.team, required this.isOwner});
  final Team team;
  final bool isOwner;

  @override
  ConsumerState<_TeamAiKeyCard> createState() => _TeamAiKeyCardState();
}

class _TeamAiKeyCardState extends ConsumerState<_TeamAiKeyCard> {
  final _key = TextEditingController();

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _save(String? key) async {
    final ok = await runAction(
      context,
      () => ref
          .read(teamRepositoryProvider)
          .setTeamGeminiKey(teamId: widget.team.id, key: key),
      success: key == null ? 'Chave da equipa removida' : 'Chave guardada',
    );
    if (ok) _key.clear();
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = ref.watch(teamGeminiKeyProvider).value != null;
    final muted = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return SectionCard(
      title: 'Gemini da equipa',
      icon: hasKey ? Icons.key : Icons.key_off_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hasKey
                ? 'A equipa tem uma chave do Gemini. Quem não tiver chave '
                      'própria usa esta no estudo de mercado e na importação.'
                : 'Ainda sem chave da equipa.',
          ),
          if (widget.isOwner) ...[
            gapH8,
            Text(
              'A quota grátis é partilhada por todos os membros, e qualquer '
              'membro consegue ver a chave. Para a trocar, crie outra no '
              'Google AI Studio e cole-a aqui.',
              style: muted,
            ),
            gapH16,
            TextField(
              controller: _key,
              obscureText: true,
              decoration: InputDecoration(
                labelText: hasKey ? 'Nova chave' : 'Chave do Gemini',
                hintText: 'AIza...',
              ),
            ),
            gapH16,
            Wrap(
              alignment: WrapAlignment.end,
              spacing: Sizes.p8,
              children: [
                if (hasKey)
                  TextButton(
                    onPressed: () => _save(null),
                    child: const Text('Remover'),
                  ),
                FilledButton(
                  onPressed: () {
                    final key = emptyToNull(_key.text.trim());
                    if (key != null) _save(key);
                  },
                  child: const Text('Guardar chave'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
