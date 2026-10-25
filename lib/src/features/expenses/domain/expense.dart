import 'package:equatable/equatable.dart';
import 'package:imovio/src/utils/format.dart';

typedef ExpenseID = String;

class ExpenseCategories {
  static const all = [
    'Publicidade e portais',
    'Fotografia e vídeo',
    'Deslocações',
    'Documentação e certidões',
    'Obras e reparações',
    'Limpeza',
    'Parcerias e referências',
    'Outros',
  ];
}

/// Despesa ligada a um imóvel, em `users/{uid}/despesas/{id}`.
class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.propertyId,
    required this.description,
    required this.amount,
    this.category = 'Outros',
    this.date,
    this.createdAt,
  });

  final ExpenseID id;
  final String propertyId;
  final String description;
  final String category;
  final num amount;
  final DateTime? date;
  final int? createdAt;

  factory Expense.fromMap(Map<String, dynamic> data, String id) {
    String? s(String key) => emptyToNull(data[key]?.toString());
    return Expense(
      id: id,
      propertyId: s('propertyId') ?? '',
      description: s('description') ?? '(sem descrição)',
      category: s('category') ?? 'Outros',
      amount: parseNum(data['amount']) ?? 0,
      date: parseDate(data['date']),
      createdAt: parseMillis(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'propertyId': propertyId,
    'description': description,
    'category': category,
    'amount': amount,
    'date': date == null ? '' : formatIsoDate(date!),
    'createdAt': ?createdAt,
  };

  Expense copyWith({int? createdAt}) => Expense(
    id: id,
    propertyId: propertyId,
    description: description,
    category: category,
    amount: amount,
    date: date,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    propertyId,
    description,
    category,
    amount,
    date,
    createdAt,
  ];
}
