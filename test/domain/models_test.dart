import 'package:flutter_test/flutter_test.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';
import 'package:imovio/src/utils/format.dart';

void main() {
  group('dados da app original', () {
    test('imóvel com preço e áreas em texto', () {
      final p = Property.fromMap({
        'title': 'T2 Corroios',
        'price': '350000',
        'areaBruta': '80',
        'img': 'https://x/capa.jpg',
        'tags': 'Apartamento · T2',
        'createdAt': 1700000000000,
      }, 'p1');
      expect(p.price, 350000);
      expect(p.areaBruta, 80);
      expect(p.images, ['https://x/capa.jpg']);
      expect(p.cover, 'https://x/capa.jpg');
      expect(p.toMap()['img'], 'https://x/capa.jpg');
    });

    test('negócio com valor em texto', () {
      final d = Deal.fromMap(
          {'title': 'Terreno', 'value': '4080', 'stage': 'Qualificação'}, 'd1');
      expect(d.value, 4080);
      expect(d.stage, DealStages.qualification);
    });

    test('tarefa com data do campo datetime-local', () {
      final t = Task.fromMap({
        'title': 'Visita',
        'category': TaskCategories.visit,
        'date': '2026-10-25T14:30',
        'status': 'Pendente',
      }, 't1');
      expect(t.date, DateTime(2026, 10, 25, 14, 30));
      expect(t.toMap()['date'], '2026-10-25T14:30');
      expect(t.isOverdue(DateTime(2026, 10, 26)), isTrue);
      expect(
          t
              .copyWith(status: TaskStatuses.done)
              .isOverdue(DateTime(2026, 10, 26)),
          isFalse);
    });

    test('contacto sem campos opcionais', () {
      final c = Contact.fromMap({'name': 'Manuel', 'type': 'Vendedor'}, 'c1');
      expect(c.originLabel, 'Particular');
      expect(c.preferences.isEmpty, isTrue);
      expect(c.toMap().containsKey('createdAt'), isFalse);
    });
  });

  test('parseNum aceita números, texto e vírgula decimal', () {
    expect(parseNum(12), 12);
    expect(parseNum('4080'), 4080);
    expect(parseNum('4080,5'), 4080.5);
    expect(parseNum(''), isNull);
    expect(parseNum(null), isNull);
  });
}
