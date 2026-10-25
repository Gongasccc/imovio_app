// Repositórios em memória para o modo demonstração. Cada um estende o
// repositório real e substitui os métodos, por isso os ecrãs funcionam
// sem alterações (criar, editar e apagar incluídos).
import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
import 'package:firebase_storage/firebase_storage.dart' show FirebaseStorage;
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/features/contacts/data/contacts_repository.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/expenses/data/expenses_repository.dart';
import 'package:imovio/src/features/expenses/domain/expense.dart';
import 'package:imovio/src/features/market_study/data/market_study_repository.dart';
import 'package:imovio/src/features/market_study/domain/comparable_listing.dart';
import 'package:imovio/src/features/market_study/domain/study_settings.dart';
import 'package:imovio/src/features/pipeline/data/deals_repository.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/settings/data/settings_repository.dart';
import 'package:imovio/src/features/settings/domain/user_settings.dart';
import 'package:imovio/src/features/tasks/data/tasks_repository.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';

class NoFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Firestore não existe no modo demonstração');
}

class NoStorage implements FirebaseStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Storage não existe no modo demonstração');
}

/// Uma "coleção" em memória: documentos por id e um stream que emite a
/// lista completa a cada alteração.
class MemoryCollection {
  final docs = <String, Map<String, dynamic>>{};
  final _changes = StreamController<void>.broadcast();
  var _next = 0;

  String newId() => 'demo-${DateTime.now().microsecondsSinceEpoch}-${_next++}';

  Stream<List<T>> watch<T>(
    T Function(Map<String, dynamic>, String) fromMap,
  ) async* {
    List<T> snapshot() => [
      for (final e in docs.entries) fromMap(Map.of(e.value), e.key),
    ];
    yield snapshot();
    yield* _changes.stream.map((_) => snapshot());
  }

  Stream<T?> watchDoc<T>(
    String id,
    T Function(Map<String, dynamic>, String) fromMap,
  ) async* {
    T? current() => docs[id] == null ? null : fromMap(Map.of(docs[id]!), id);
    yield current();
    yield* _changes.stream.map((_) => current());
  }

  Future<String> add(Map<String, dynamic> data) async {
    final id = newId();
    docs[id] = data;
    _changes.add(null);
    return id;
  }

  Future<void> set(
    String id,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    docs[id] = merge ? {...?docs[id], ...data} : data;
    _changes.add(null);
  }

  Future<void> delete(String id) async {
    docs.remove(id);
    _changes.add(null);
  }
}

int get _now => DateTime.now().millisecondsSinceEpoch;

class DemoContactsRepository extends ContactsRepository {
  DemoContactsRepository(this.c) : super(NoFirestore());
  final MemoryCollection c;

  @override
  Stream<List<Contact>> watchContacts({required UserID uid}) => c
      .watch(Contact.fromMap)
      .map(
        (l) => l
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          ),
      );

  @override
  Future<ContactID> addContact({
    required UserID uid,
    required Contact contact,
  }) => c.add(contact.copyWith(createdAt: _now, updatedAt: _now).toMap());

  @override
  Future<void> updateContact({required UserID uid, required Contact contact}) =>
      c.set(contact.id, contact.toMap()..remove('createdAt'), merge: true);

  @override
  Future<void> deleteContact({required UserID uid, required ContactID id}) =>
      c.delete(id);
}

class DemoTasksRepository extends TasksRepository {
  DemoTasksRepository(this.c) : super(NoFirestore());
  final MemoryCollection c;

  @override
  Stream<List<Task>> watchTasks({required UserID uid}) =>
      c.watch(Task.fromMap).map((l) => l..sort(compareTasks));

  @override
  Future<void> addTask({required UserID uid, required Task task}) =>
      c.add(task.copyWith(createdAt: _now).toMap());

  @override
  Future<void> updateTask({required UserID uid, required Task task}) =>
      c.set(task.id, task.toMap()..remove('createdAt'), merge: true);

  @override
  Future<void> setDone({
    required UserID uid,
    required TaskID id,
    required bool done,
  }) => c.set(id, {
    'status': done ? TaskStatuses.done : TaskStatuses.pending,
  }, merge: true);

  @override
  Future<void> deleteTask({required UserID uid, required TaskID id}) =>
      c.delete(id);
}

class DemoDealsRepository extends DealsRepository {
  DemoDealsRepository(this.c) : super(NoFirestore());
  final MemoryCollection c;

  @override
  Stream<List<Deal>> watchDeals({required UserID uid}) => c
      .watch(Deal.fromMap)
      .map(
        (l) =>
            l..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0)),
      );

  @override
  Future<void> addDeal({required UserID uid, required Deal deal}) =>
      c.add(deal.copyWith(createdAt: _now).toMap());

  @override
  Future<void> updateDeal({required UserID uid, required Deal deal}) =>
      c.set(deal.id, deal.toMap()..remove('createdAt'), merge: true);

  @override
  Future<void> moveDeal({
    required UserID uid,
    required DealID id,
    required String stage,
  }) => c.set(id, {'stage': stage}, merge: true);

  @override
  Future<void> deleteDeal({required UserID uid, required DealID id}) =>
      c.delete(id);
}

class DemoPropertiesRepository extends PropertiesRepository {
  DemoPropertiesRepository(this.c) : super(NoFirestore(), NoStorage());
  final MemoryCollection c;

  @override
  Stream<List<Property>> watchProperties({required UserID uid}) => c
      .watch(Property.fromMap)
      .map(
        (l) =>
            l..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0)),
      );

  @override
  Stream<Property?> watchProperty({
    required UserID uid,
    required PropertyID id,
  }) => c.watchDoc(id, Property.fromMap);

  @override
  PropertyID newId(UserID uid) => c.newId();

  @override
  Future<void> createProperty({
    required UserID uid,
    required Property property,
  }) => c.set(property.id, property.copyWith(createdAt: _now).toMap());

  @override
  Future<void> updateProperty({
    required UserID uid,
    required Property property,
  }) => c.set(property.id, property.toMap()..remove('createdAt'), merge: true);

  @override
  Future<void> deleteProperty({required UserID uid, required PropertyID id}) =>
      c.delete(id);

  @override
  Future<String> uploadPhoto({
    required UserID uid,
    required PropertyID propertyId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) => throw UnsupportedError(
    'No modo demonstração as fotos só podem ser adicionadas por URL.',
  );
}

class DemoExpensesRepository extends ExpensesRepository {
  DemoExpensesRepository(this.c) : super(NoFirestore());
  final MemoryCollection c;

  @override
  Stream<List<Expense>> watchExpenses({required UserID uid}) => c
      .watch(Expense.fromMap)
      .map(
        (l) => l
          ..sort(
            (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)),
          ),
      );

  @override
  Future<void> addExpense({required UserID uid, required Expense expense}) =>
      c.add(expense.copyWith(createdAt: _now).toMap());

  @override
  Future<void> updateExpense({required UserID uid, required Expense expense}) =>
      c.set(expense.id, expense.toMap()..remove('createdAt'), merge: true);

  @override
  Future<void> deleteExpense({required UserID uid, required ExpenseID id}) =>
      c.delete(id);
}

class DemoSettingsRepository extends SettingsRepository {
  DemoSettingsRepository(this.c) : super(NoFirestore());
  final MemoryCollection c;

  @override
  Stream<UserSettings> watchSettings({required UserID uid}) => c
      .watchDoc('config', (m, _) => UserSettings.fromMap(m))
      .map((s) => s ?? const UserSettings());

  @override
  Future<void> setSettings({
    required UserID uid,
    required UserSettings settings,
  }) => c.set('config', settings.toMap(), merge: true);
}

class DemoMarketStudyRepository extends MarketStudyRepository {
  DemoMarketStudyRepository(this.comparables, this.settings)
    : super(NoFirestore());
  final MemoryCollection comparables;
  final MemoryCollection settings;

  @override
  Stream<List<ComparableListing>> watchComparables({required UserID uid}) =>
      comparables.watch(ComparableListing.fromMap);

  @override
  ComparableID newComparableId(UserID uid) => comparables.newId();

  @override
  Future<void> saveComparable({
    required UserID uid,
    required ComparableListing comparable,
  }) => comparables.set(comparable.id, comparable.toMap());

  @override
  Future<void> deleteComparable({
    required UserID uid,
    required ComparableID id,
  }) => comparables.delete(id);

  @override
  Stream<StudySettings> watchSettings({
    required UserID uid,
    required PropertyID propertyId,
  }) => settings
      .watchDoc(propertyId, (m, _) => StudySettings.fromMap(m))
      .map((s) => s ?? StudySettings.fromMap(null));

  @override
  Future<void> saveSettings({
    required UserID uid,
    required PropertyID propertyId,
    required StudySettings settings,
  }) => this.settings.set(propertyId, settings.toMap());
}
