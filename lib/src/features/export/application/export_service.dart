import 'dart:typed_data';

import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/expenses/domain/expense.dart';
import 'package:imovio/src/features/export/application/xlsx_writer.dart';
import 'package:imovio/src/features/interactions/domain/interaction.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/properties/application/sale_summary.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/features/tasks/domain/task.dart';
import 'package:imovio/src/utils/format.dart';

/// Cópia de segurança de tudo num Excel, uma folha por tipo de registo.
Uint8List exportAllToXlsx({
  required List<Contact> contacts,
  required List<Property> properties,
  required List<Deal> deals,
  required List<Task> tasks,
  required List<Expense> expenses,
  required List<Interaction> interactions,
}) {
  final contactName = {for (final c in contacts) c.id: c.name};
  final propertyTitle = {for (final p in properties) p.id: p.title};
  DateTime? millis(int? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);

  return buildXlsx([
    XlsxSheet(
      'Contactos',
      ['Nome', 'Tipo', 'Telefone', 'Email', 'Origem', 'NIF', 'Documento',
        'Morada', 'Código postal', 'Localidade', 'Procura (negócio)',
        'Procura (tipo)', 'Procura (tipologia)', 'Procura (concelhos)',
        'Preço mín. (€)', 'Preço máx. (€)', 'Notas', 'Criado em'],
      [
        for (final c in contacts)
          [c.name, c.type, c.phone, c.email, c.origin, c.nif, c.idNum,
            c.address, c.zip, c.city, c.preferences.negocios,
            c.preferences.tipos, c.preferences.tipologias,
            c.preferences.concelhos, c.preferences.minPrice,
            c.preferences.maxPrice, c.notes, millis(c.createdAt)],
      ],
    ),
    XlsxSheet(
      'Imóveis',
      ['Título', 'Negócio', 'Tipo', 'Tipologia', 'Preço (€)', 'Vendido por (€)',
        'Estado', 'Contrato', 'Pleno/Partilha', 'Comissão %',
        'Comissão agência (€)', 'A sua parte (€)', 'Despesas (€)',
        'Lucro real (€)', 'Área útil (m²)', 'Área bruta (m²)', 'Quartos', 'WC',
        'Distrito', 'Concelho', 'Freguesia', 'Morada', 'Código postal',
        'Proprietário', 'Angariação', 'Fecho', 'Link'],
      [
        for (final p in properties)
          () {
            final s = computeSaleSummary(
                p, expenses.where((e) => e.propertyId == p.id).toList());
            return [p.title, p.negocio, p.tipo, p.tipologia, p.price,
              p.salePrice, p.saleStatus, p.contractType, p.saleMode,
              p.commissionPct, s.agencyCommission, s.agentShare,
              s.expensesTotal, s.profit, p.areaUtil, p.areaBruta, p.quartos,
              p.wc, p.distrito, p.concelho, p.freguesia, p.morada, p.cp,
              contactName[p.ownerId], parseDate(p.dateStart),
              parseDate(p.dateEnd), p.sourceUrl];
          }(),
      ],
    ),
    XlsxSheet(
      'Negócios',
      ['Título', 'Fase', 'Valor (€)', 'Cliente', 'Imóvel', 'Notas', 'Criado em'],
      [
        for (final d in deals)
          [d.title, d.stage, d.value, contactName[d.contactId],
            propertyTitle[d.propertyId], d.notes, millis(d.createdAt)],
      ],
    ),
    XlsxSheet(
      'Tarefas',
      ['Título', 'Categoria', 'Estado', 'Data', 'Cliente', 'Imóvel', 'Notas'],
      [
        for (final t in tasks)
          [t.title, t.category, t.status, t.date, contactName[t.contactId],
            propertyTitle[t.propertyId], t.notes],
      ],
    ),
    XlsxSheet(
      'Despesas',
      ['Data', 'Imóvel', 'Descrição', 'Categoria', 'Valor (€)'],
      [
        for (final e in expenses)
          [e.date, propertyTitle[e.propertyId], e.description, e.category,
            e.amount],
      ],
    ),
    XlsxSheet(
      'Interações',
      ['Data', 'Tipo', 'Contacto', 'Imóvel', 'Nota', 'Gostou (1-5)',
        'Preço', 'Interessado'],
      [
        for (final i in interactions)
          [i.at, i.kind.label, contactName[i.contactId],
            propertyTitle[i.propertyId], i.note, i.rating, i.priceOpinion,
            i.interested],
      ],
    ),
  ]);
}
