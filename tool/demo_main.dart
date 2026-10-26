// Modo demonstração: a app completa com dados de exemplo em memória, sem
// Firebase nem login. Serve para rever o visual e testar fluxos.
//
//   flutter run -t tool/demo_main.dart -d chrome
//
// Nada do que se faz aqui toca nos dados reais; ao recarregar a página os
// dados de exemplo voltam ao início.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imovio/src/features/templates/data/templates_repository.dart';
import 'package:imovio/src/features/interactions/data/interactions_repository.dart';
import 'package:imovio/src/features/goals/data/goals_repository.dart';
import 'package:imovio/src/app.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/expenses/data/expenses_repository.dart';
import 'package:imovio/src/features/market_study/data/market_study_repository.dart';
import 'package:imovio/src/features/pipeline/data/deals_repository.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/settings/data/local_preferences.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';

import 'demo_data.dart';
import 'demo_repositories.dart';

class _DemoUser implements User {
  @override
  String get uid => demoUid;
  @override
  String? get email => 'demo@imovio.pt';
  @override
  String? get displayName => 'Consultor Demo';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoFirebaseAuth implements FirebaseAuth {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Sessão sempre iniciada; "Entrar" aceita qualquer email e palavra-passe.
class _DemoAuthRepository extends AuthRepository {
  _DemoAuthRepository() : super(_NoFirebaseAuth());
  final _user = _DemoUser();
  final _controller = StreamController<User?>.broadcast();
  late User? _current = _user;

  @override
  User? get currentUser => _current;

  @override
  Stream<User?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    _current = _user;
    _controller.add(_user);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }
}

MemoryCollection _seed(Iterable<(String, Map<String, dynamic>)> docs) {
  final c = MemoryCollection();
  for (final (id, data) in docs) {
    c.docs[id] = data;
  }
  return c;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_PT';
  await initializeDateFormatting('pt_PT');
  final prefs = await SharedPreferences.getInstance();

  final contacts = _seed(demoContacts.map((c) => (c.id, c.toMap())));
  final properties = _seed(demoProperties.map((p) => (p.id, p.toMap())));
  final deals = _seed(demoDeals.map((d) => (d.id, d.toMap())));
  final tasks = _seed(demoTasks.map((t) => (t.id, t.toMap())));
  final expenses = _seed(demoExpenses.map((e) => (e.id, e.toMap())));
  final settings = _seed([
    (
      'config',
      {'theme': 'dark', 'defaultCommissionPct': 5, 'defaultAgentSplitPct': 50},
    ),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_DemoAuthRepository()),
        sharedPreferencesProvider.overrideWithValue(prefs),
        contactsRepositoryProvider.overrideWithValue(
          DemoContactsRepository(contacts),
        ),
        propertiesRepositoryProvider.overrideWithValue(
          DemoPropertiesRepository(properties),
        ),
        dealsRepositoryProvider.overrideWithValue(DemoDealsRepository(deals)),
        tasksRepositoryProvider.overrideWithValue(DemoTasksRepository(tasks)),
        expensesRepositoryProvider.overrideWithValue(
          DemoExpensesRepository(expenses),
        ),
        settingsRepositoryProvider.overrideWithValue(
          DemoSettingsRepository(settings),
        ),
        interactionsRepositoryProvider
          .overrideWithValue(DemoInteractionsRepository(MemoryCollection())),
      templatesRepositoryProvider
          .overrideWithValue(DemoTemplatesRepository(MemoryCollection())),
      goalsRepositoryProvider.overrideWithValue(DemoGoalsRepository(_seed([
        ('goals', {'angariacoes': 3, 'visitas': 10, 'propostas': 4, 'vendas': 1, 'lucro': 5000}),
      ]))),
      marketStudyRepositoryProvider.overrideWithValue(
          DemoMarketStudyRepository(MemoryCollection(), MemoryCollection()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
