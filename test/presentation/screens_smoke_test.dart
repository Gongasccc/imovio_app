import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' show FirebaseStorage;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imovio/src/features/settings/data/local_preferences.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/contacts/presentation/contact_edit_screen.dart';
import 'package:imovio/src/features/contacts/presentation/contacts_screen.dart';
import 'package:imovio/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:imovio/src/features/pipeline/data/deals_repository.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/pipeline/presentation/deal_edit_screen.dart';
import 'package:imovio/src/features/pipeline/presentation/pipeline_screen.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/properties/presentation/properties_screen.dart';
import 'package:imovio/src/features/properties/presentation/property_detail_screen.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';
import 'package:imovio/src/features/tasks/presentation/task_edit_screen.dart';
import 'package:imovio/src/features/tasks/presentation/tasks_screen.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

class _MockStorage extends Mock implements FirebaseStorage {}

final _contacts = [
  const Contact(
    id: 'c1',
    name: 'Manuel José Bento Palma',
    email: 'manuel@exemplo.pt',
    phone: '918515243',
    type: ContactTypes.buyer,
    origin: 'idealista',
    preferences:
        PropertyPreferences(concelho: 'Almada', tipologia: 'T2', maxPrice: 300000),
  ),
  const Contact(id: 'c2', name: 'Ana Vendedora', type: ContactTypes.seller),
];

final _properties = [
  const Property(
    id: 'p1',
    title: 'Apartamento T2 em Corroios com varanda',
    price: 249000,
    negocio: 'Venda',
    tipo: 'Apartamento',
    tipologia: 'T2',
    concelho: 'Almada',
    distrito: 'Setúbal',
    areaBruta: 80,
    quartos: 2,
    wc: 1,
    ownerId: 'c2',
    images: ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
    sourceUrl: 'https://example.com/anuncio',
  ),
];

final _deals = [
  const Deal(
      id: 'd1',
      title: 'Terreno Rua João de Deus - Charneca da Caparica',
      contactId: 'c1',
      propertyId: 'p1',
      value: 4080,
      stage: DealStages.qualification),
  const Deal(id: 'd2', title: 'Proposta T3', value: 1500),
];

final _tasks = [
  Task(
      id: 't1',
      title: 'Visita ao T2',
      category: TaskCategories.visit,
      contactId: 'c1',
      propertyId: 'p1',
      date: DateTime.now().add(const Duration(hours: 2))),
  Task(
      id: 't2',
      title: 'Escritura – previsão até 5 meses após CPCV',
      category: TaskCategories.cpcv,
      date: DateTime.now().subtract(const Duration(days: 3))),
  const Task(id: 't3', title: 'Ligar ao banco', status: TaskStatuses.done),
];

late SharedPreferences _prefs;

Widget _app(Widget child) => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_prefs),
        firestoreProvider.overrideWithValue(_MockFirestore()),
        firebaseStorageProvider.overrideWithValue(_MockStorage()),
        currentUidProvider.overrideWithValue('uid-teste'),
        contactsStreamProvider.overrideWith((ref) => Stream.value(_contacts)),
        propertiesStreamProvider
            .overrideWith((ref) => Stream.value(_properties)),
        propertyStreamProvider('p1')
            .overrideWith((ref) => Stream.value(_properties.first)),
        dealsStreamProvider.overrideWith((ref) => Stream.value(_deals)),
        tasksStreamProvider.overrideWith((ref) => Stream.value(_tasks)),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        locale: const Locale('pt', 'PT'),
        supportedLocales: const [Locale('pt', 'PT')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    );

void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'pt_PT';
    await initializeDateFormatting('pt_PT');
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  final screens = <String, Widget>{
    'dashboard': const DashboardScreen(),
    'contactos': const ContactsScreen(),
    'ficha de contacto': const ContactEditScreen(contactId: 'c1'),
    'novo contacto': const ContactEditScreen(),
    'imóveis': const PropertiesScreen(),
    'detalhe do imóvel': const PropertyDetailScreen(propertyId: 'p1'),
    'pipeline': const PipelineScreen(),
    'editar negócio': const DealEditScreen(dealId: 'd1'),
    'tarefas': const TasksScreen(),
    'editar tarefa': const TaskEditScreen(taskId: 't1'),
  };

  for (final size in const [Size(390, 844), Size(1400, 900)]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} desenha sem erros a ${size.width.toInt()}px',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(entry.value));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('ficha do contacto mostra imóveis compatíveis e histórico',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const ContactEditScreen(contactId: 'c1')));
    await tester.pump();
    await tester.tap(find.text('2. Imóvel'));
    await tester.pumpAndSettle();
    expect(find.text('Apartamento T2 em Corroios com varanda'), findsOneWidget);
    await tester.tap(find.text('3. Histórico e Tarefas'));
    await tester.pumpAndSettle();
    expect(find.text('Visita ao T2'), findsOneWidget);
    expect(find.textContaining('Charneca'), findsOneWidget);
  });

  testWidgets('dashboard mostra KPIs e lembrete em atraso', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const DashboardScreen()));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Em atraso'), findsOneWidget);
    // 2 contactos, 2 negócios e 2 tarefas pendentes.
    expect(find.text('2'), findsNWidgets(3));
  });

  testWidgets('comissão é calculada ao mudar a percentagem', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const PropertyDetailScreen(propertyId: 'p1')));
    await tester.pump();
    await tester.tap(find.text('3. Detalhes de Venda'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Comissão (%)'), '4');
    await tester.pump();
    expect(find.text('9960.00'), findsOneWidget);
  });
}
