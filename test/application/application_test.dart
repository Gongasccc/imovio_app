import 'package:flutter_test/flutter_test.dart';
import 'package:imovio/src/features/contacts/application/contacts_csv.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/dashboard/application/dashboard_service.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/properties/application/commission.dart';
import 'package:imovio/src/features/properties/application/listing_import_service.dart';
import 'package:imovio/src/features/properties/application/property_matching.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';

void main() {
  test('comissão de 5% sobre 350 000 €', () {
    expect(commissionValue(price: 350000, percent: 5), 17500);
    expect(commissionValue(price: 123456, percent: 4.5), 5555.52);
    expect(commissionValue(price: null, percent: 5), isNull);
  });

  group('importação por link', () {
    test('deduz preço, tipo, negócio e tipologia do texto', () {
      final l = ListingImportService.fromText(
        title: 'Apartamento T2 em Corroios | iad Portugal',
        description: 'Apartamento para venda por 249.000 € com 80m2',
      );
      expect(l.title, 'Apartamento T2 em Corroios');
      expect(l.price, 249000);
      expect(l.tipo, 'Apartamento');
      expect(l.negocio, 'Venda');
      expect(l.tipologia, 'T2');
    });

    test('sem preço no anúncio fica vazio (não inventa 350 000 €)', () {
      final l = ListingImportService.fromText(title: 'Moradia para arrendar');
      expect(l.price, isNull);
      expect(l.negocio, 'Arrendamento');
      expect(l.tipo, 'Moradia');
    });

    test('lê meta tags og', () {
      const html = '<meta property="og:image" content="https://x/a.jpg">'
          '<meta content="Casa &amp; jardim" property="og:title">';
      expect(ListingImportService.metaContent(html, 'og:image'),
          'https://x/a.jpg');
      expect(ListingImportService.metaContent(html, 'og:title'),
          'Casa & jardim');
    });
  });

  group('imóveis compatíveis', () {
    const buyer = Contact(
      id: 'c1',
      name: 'Ana',
      type: ContactTypes.buyer,
      preferences: PropertyPreferences(
          concelho: 'Almada', tipologia: 'T2', maxPrice: 300000),
    );
    const match = Property(
        id: 'a',
        title: 'A',
        negocio: 'Venda',
        concelho: 'almada',
        tipologia: 'T2',
        price: 250000);
    const tooExpensive = Property(
        id: 'b',
        title: 'B',
        negocio: 'Venda',
        concelho: 'Almada',
        tipologia: 'T2',
        price: 400000);
    const rental = Property(
        id: 'c',
        title: 'C',
        negocio: 'Arrendamento',
        concelho: 'Almada',
        tipologia: 'T2',
        price: 900);
    const sold = Property(
        id: 'd',
        title: 'D',
        negocio: 'Venda',
        concelho: 'Almada',
        tipologia: 'T2',
        price: 200000,
        saleStatus: 'Vendido');

    test('filtra por preferências e negócio', () {
      final result =
          matchingProperties(buyer, [match, tooExpensive, rental, sold]);
      expect(result.map((p) => p.id), ['a']);
    });

    test('vendedores e contactos sem preferências não têm sugestões', () {
      const seller = Contact(
          id: 's',
          name: 'S',
          type: ContactTypes.seller,
          preferences: PropertyPreferences(concelho: 'Almada'));
      const empty = Contact(id: 'e', name: 'E');
      expect(matchingProperties(seller, [match]), isEmpty);
      expect(matchingProperties(empty, [match]), isEmpty);
    });
  });

  test('KPIs do dashboard e lembretes', () {
    final now = DateTime(2026, 10, 25, 12);
    final k = computeKpis(
      contacts: const [Contact(id: 'c', name: 'C')],
      properties: const [],
      deals: const [
        Deal(id: '1', title: 'a', value: 1000),
        Deal(id: '2', title: 'b', value: 2500),
      ],
      tasks: [
        Task(id: 'late', title: 'x', date: DateTime(2026, 10, 20)),
        Task(id: 'today', title: 'y', date: DateTime(2026, 10, 25, 18)),
        Task(id: 'soon', title: 'z', date: DateTime(2026, 10, 28)),
        Task(
            id: 'done',
            title: 'w',
            status: TaskStatuses.done,
            date: DateTime(2026, 10, 20)),
      ],
      now: now,
    );
    expect(k.contacts, 1);
    expect(k.pipelineValue, 3500);
    expect(k.pendingTasks, 3);
    expect(k.overdueTasks.map((t) => t.id), ['late']);
    expect(k.todayTasks.map((t) => t.id), ['today']);
    expect(k.upcomingTasks.map((t) => t.id), ['soon']);
  });

  test('CSV escapa aspas e mantém colunas', () {
    final csv = contactsToCsv(const [
      Contact(id: '1', name: 'Rui "Zé" Silva', email: 'rui@x.pt'),
    ]);
    final lines = csv.trim().split('\n');
    expect(lines.first, startsWith('Nome,Email,Telefone,Tipo,Origem,Morada'));
    expect(lines[1], startsWith('"Rui ""Zé"" Silva","rui@x.pt"'));
  });
}
