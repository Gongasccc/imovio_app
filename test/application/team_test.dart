import 'package:flutter_test/flutter_test.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/team/application/sponsor_earnings.dart';
import 'package:imovio/src/features/team/application/team_sync.dart';
import 'package:imovio/src/features/team/domain/afilhado_sale.dart';
import 'package:imovio/src/features/team/domain/team.dart';
import 'package:imovio/src/features/team/domain/team_listing.dart';

Property _property(
  String id, {
  String? status,
  num? price = 200000,
  num? salePrice,
}) => Property(
  id: id,
  title: 'Imóvel $id',
  price: price,
  salePrice: salePrice,
  saleStatus: status,
  commissionPct: 5,
  agentSplitPct: 50,
  ownerId: 'contacto-secreto',
  morada: 'Rua Secreta 1',
  saleNotes: 'nota privada',
  concelho: 'Almada',
);

const _ana = TeamMember(uid: 'ana', name: 'Ana', sponsorUid: 'goncalo');

void main() {
  group('partilha com a equipa', () {
    test('não partilha proprietário, morada, comissões nem notas', () {
      final data = TeamListing.publicData(
        property: _property('p1'),
        agentUid: 'ana',
        agentName: 'Ana',
      );
      for (final key in [
        'ownerId',
        'morada',
        'cp',
        'commissionPct',
        'commissionVal',
        'agentSplitPct',
        'salePrice',
        'saleNotes',
        'sourceUrl',
      ]) {
        expect(data.containsKey(key), isFalse, reason: key);
      }
      expect(data['concelho'], 'Almada');
      expect(data['agentName'], 'Ana');
      final back = TeamListing.fromMap(data, 'ana_p1');
      expect(back.property.price, 200000);
      expect(back.agentUid, 'ana');
    });

    test('vendidos e escondidos ficam de fora', () {
      final docs = desiredListings(
        uid: 'ana',
        agentName: 'Ana',
        properties: [
          _property('p1'),
          _property('p2', status: 'Vendido'),
          _property('p3'),
        ],
        hidden: ['p3'],
      );
      expect(docs.keys, ['ana_p1']);
    });
  });

  group('números de venda para o padrinho', () {
    test('envia a parte da afilhada calculada como no resumo de venda', () {
      final docs = desiredSales(
        me: _ana,
        properties: [_property('p1', status: 'Vendido', salePrice: 180000)],
        defaultAgentSplitPct: 50,
      );
      final sale = AfilhadoSale.fromMap(docs['ana_p1']!, 'ana_p1');
      // 180 000 × 5 % = 9 000 de comissão; metade para a Ana.
      expect(sale.agentShare, 4500);
      expect(sale.sponsorUid, 'goncalo');
      expect(sale.isSold, isTrue);
      expect(docs['ana_p1']!.containsKey('ownerId'), isFalse);
    });

    test('sem padrinho não envia nada', () {
      final docs = desiredSales(
        me: const TeamMember(uid: 'ana', name: 'Ana'),
        properties: [_property('p1')],
        defaultAgentSplitPct: 50,
      );
      expect(docs, isEmpty);
    });

    test('imóveis sem preço não contam', () {
      final docs = desiredSales(
        me: _ana,
        properties: [_property('p1', price: null)],
        defaultAgentSplitPct: 50,
      );
      expect(docs, isEmpty);
    });
  });

  group('sincronização', () {
    test('só escreve o que mudou e apaga o que desapareceu', () {
      final plan = planSync(
        {
          'a': {'price': 5.0, 'images': ['x']},
          'b': {'price': 1},
          'c': {'price': 1},
        },
        {
          'a': {'images': ['x'], 'price': 5},
          'b': {'price': 2},
          'd': {'price': 3},
        },
      );
      expect(plan.sets.keys, unorderedEquals(['b', 'd']));
      expect(plan.deletes, ['c']);
    });

    test('alterar o imóvel atualiza logo o padrinho', () async {
      final applied = <SyncPlan>[];
      final service = TeamSyncService(
        loadListings: (_, _) async => {},
        loadSales: (_, _) async => {},
        apply: (teamId, {required listings, required sales}) async {
          applied.add(sales);
        },
      );
      Future<void> sync(List<Property> properties) => service.sync(
        teamId: 't',
        me: _ana,
        properties: properties,
        hidden: const [],
        defaultAgentSplitPct: 50,
      );
      await sync([_property('p1', status: 'Reservado')]);
      await sync([_property('p1', status: 'Reservado')]);
      await sync([_property('p1', status: 'Vendido', salePrice: 190000)]);
      await sync(const []);
      expect(applied, hasLength(3));
      expect(applied[1].sets['ana_p1']!['saleStatus'], 'Vendido');
      expect(applied[1].sets['ana_p1']!['agentShare'], 4750);
      expect(applied[2].deletes, ['ana_p1']);
    });

    test('se a escrita falhar, volta a tentar na alteração seguinte', () async {
      var calls = 0;
      final service = TeamSyncService(
        loadListings: (_, _) async => {},
        loadSales: (_, _) async => {},
        apply: (teamId, {required listings, required sales}) async {
          calls++;
          if (calls == 1) throw Exception('permission-denied');
        },
      );
      for (var i = 0; i < 2; i++) {
        await service.sync(
          teamId: 't',
          me: _ana,
          properties: [_property('p1')],
          hidden: const [],
          defaultAgentSplitPct: 50,
        );
      }
      expect(calls, 2);
    });
  });

  group('ganhos do padrinho', () {
    AfilhadoSale sale(String id, String uid, String? status, num share) =>
        AfilhadoSale(
          id: id,
          afilhadoUid: uid,
          afilhadoName: uid,
          sponsorUid: 'goncalo',
          propertyId: id,
          title: id,
          saleStatus: status,
          agentShare: share,
        );

    test('% sobre a parte da afilhada, separada por fase', () {
      final earnings = computeSponsorEarnings(
        afilhados: {'ana': 'Ana', 'rui': 'Rui'},
        sales: [
          sale('1', 'ana', 'Vendido', 4500),
          sale('2', 'ana', 'CPCV Assinado', 3000),
          sale('3', 'ana', 'Em Angariação', 1000),
          sale('4', 'rui', 'Vendido', 2000),
        ],
        pcts: {'ana': 10},
      );
      final ana = earnings.afilhados.firstWhere((a) => a.afilhadoUid == 'ana');
      expect(ana.realized, 450);
      expect(ana.forecast, 300);
      expect(ana.portfolio, 100);
      // Sem % definida para o Rui, ainda não conta.
      final rui = earnings.afilhados.firstWhere((a) => a.afilhadoUid == 'rui');
      expect(rui.realized, 0);
      expect(earnings.realized, 450);
    });

    test('afilhados sem imóveis também aparecem', () {
      final earnings = computeSponsorEarnings(
        afilhados: {'ana': 'Ana'},
        sales: const [],
        pcts: const {},
      );
      expect(earnings.afilhados.single.afilhadoName, 'Ana');
    });
  });
}
