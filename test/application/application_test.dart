import 'package:flutter_test/flutter_test.dart';
import 'package:imovio/src/features/contacts/application/contacts_csv.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/dashboard/application/dashboard_service.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/expenses/domain/expense.dart';
import 'package:imovio/src/features/properties/application/commission.dart';
import 'package:imovio/src/features/properties/application/sale_summary.dart';
import 'package:imovio/src/features/properties/application/listing_parser.dart';
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
      final l = ListingParser.parseText(
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
      final l = ListingParser.parseText(title: 'Moradia para arrendar');
      expect(l.price, isNull);
      expect(l.negocio, 'Arrendamento');
      expect(l.tipo, 'Moradia');
    });

    test('lê dados estruturados JSON-LD e junta fotos repetidas', () {
      const html = '''
<html><head>
<meta property="og:title" content="Moradia T4 com piscina | Portal">
<meta property="og:image" content="https://img.portal.pt/f/1.jpg?w=1200">
<script type="application/ld+json">
{"@context":"https://schema.org","@graph":[{"@type":"Organization","name":"Portal"},
 {"@type":"SingleFamilyResidence","name":"Moradia T4 com piscina",
  "numberOfBedrooms":4,"numberOfBathroomsTotal":3,
  "floorSize":{"@type":"QuantitativeValue","value":"210","unitCode":"MTK"},
  "address":{"addressLocality":"Palmela","addressRegion":"Setúbal",
   "postalCode":"2950-123","streetAddress":"Rua das Flores 5"},
  "image":["https://img.portal.pt/f/1.jpg?w=390","https://img.portal.pt/f/2.jpg"],
  "offers":{"@type":"Offer","price":"495.000","priceCurrency":"EUR"}}]}
</script></head>
<body><p>Área bruta: 260 m² · Área do terreno: 800 m² · Certificado energético: B-</p>
<p>Garagem para 2 carros, jardim e piscina. Ano de construção: 2008</p>
<img src="https://img.portal.pt/logo.jpg"></body></html>''';
      final l = ListingParser.parse(html);
      expect(l.title, 'Moradia T4 com piscina');
      expect(l.price, 495000);
      expect(l.quartos, 4);
      expect(l.wc, 3);
      expect(l.areaUtil, 210);
      expect(l.areaBruta, 260);
      expect(l.areaTerreno, 800);
      expect(l.concelho, 'Palmela');
      expect(l.distrito, 'Setúbal');
      expect(l.cp, '2950-123');
      expect(l.morada, 'Rua das Flores 5');
      expect(l.tipo, 'Moradia');
      expect(l.tipologia, 'T4');
      expect(l.energyCertificate, 'B-');
      expect(l.year, 2008);
      expect(l.caracteristicas, containsAll(['garagem', 'jardim', 'piscina']));
      expect(l.images, [
        'https://img.portal.pt/f/1.jpg?w=1200',
        'https://img.portal.pt/f/2.jpg',
      ]);
    });

    test('lê meta tags og', () {
      const html = '<meta property="og:image" content="https://x/a.jpg">'
          '<meta content="Casa &amp; jardim" property="og:title">';
      expect(ListingParser.metaContent(html, 'og:image'),
          'https://x/a.jpg');
      expect(ListingParser.metaContent(html, 'og:title'),
          'Casa & jardim');
    });
  });

  group('imóveis compatíveis', () {
    const buyer = Contact(
      id: 'c1',
      name: 'Ana',
      type: ContactTypes.buyer,
      preferences: PropertyPreferences(
          concelhos: ['Almada'], tipologias: ['T2'], maxPrice: 300000),
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
          preferences: PropertyPreferences(concelhos: ['Almada']));
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

  group('resumo de venda', () {
    const sold = Property(
      id: 'p',
      title: 'T3',
      price: 320000,
      salePrice: 305000,
      commissionPct: 5,
      agentSplitPct: 60,
      saleStatus: 'Vendido',
      dateStart: '2026-05-10',
      dateEnd: '2026-09-28',
    );
    final expenses = [
      const Expense(id: '1', propertyId: 'p', description: 'Fotos', amount: 180),
      const Expense(id: '2', propertyId: 'p', description: 'Portal', amount: 249.9),
    ];

    test('comissão, a sua parte, despesas e lucro real', () {
      final s = computeSaleSummary(sold, expenses, defaultAgentSplitPct: 50);
      expect(s.agencyCommission, 15250);
      expect(s.agentShare, 9150);
      expect(s.expensesTotal, 429.9);
      expect(s.profit, 8720.1);
      expect(s.discount, 15000);
      expect(s.daysOnMarket, 141);
      expect(s.isSold, isTrue);
    });

    test('sem valores próprios usa o preço anunciado e a % por omissão', () {
      const p = Property(id: 'q', title: 'T2', price: 200000, commissionPct: 4);
      final s = computeSaleSummary(p, const [], defaultAgentSplitPct: 50);
      expect(s.salePrice, 200000);
      expect(s.agencyCommission, 8000);
      expect(s.agentShare, 4000);
      expect(s.profit, 4000);
      expect(s.isSold, isFalse);
    });
  });
}
