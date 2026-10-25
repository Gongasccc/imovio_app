import 'package:intl/intl.dart';

class Format {
  static final _euro = NumberFormat.currency(
    locale: 'pt_PT',
    symbol: '€',
    decimalDigits: 0,
  );
  static final _euroCents = NumberFormat.currency(
    locale: 'pt_PT',
    symbol: '€',
    decimalDigits: 2,
  );
  static final _date = DateFormat('d MMM y', 'pt_PT');
  static final _dateTime = DateFormat("d MMM y 'às' HH:mm", 'pt_PT');

  /// 350000 → "350 000 €"
  static String euros(num? value) => value == null ? '—' : _euro.format(value);

  static String eurosWithCents(num? value) =>
      value == null ? '—' : _euroCents.format(value);

  /// 85.5 → "85,5"; 1234 → "1234".
  static String number(num? value) => value == null
      ? '—'
      : NumberFormat.decimalPatternDigits(locale: 'pt_PT', decimalDigits: 1)
          .format(value)
          .replaceAll(RegExp(r',0$'), '');

  /// 0.052 → "+5,2 %" (com sinal) ou "5,2 %".
  static String percent(num? value, {bool signed = false, int decimals = 1}) {
    if (value == null) return '—';
    final text = NumberFormat.decimalPatternDigits(
            locale: 'pt_PT', decimalDigits: decimals)
        .format(value * 100);
    return '${signed && value > 0 ? '+' : ''}$text %';
  }

  static String date(DateTime? date) => date == null ? '—' : _date.format(date);

  static String dateTime(DateTime? date) =>
      date == null ? '—' : _dateTime.format(date);
}

/// Lê um número guardado no Firestore como número ou como texto
/// ("350000", "350.000", "4080,5"). A app original guardava tudo como texto.
num? parseNum(Object? value) {
  if (value == null) return null;
  if (value is num) return value;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final direct = num.tryParse(text);
  if (direct != null) return direct;
  final normalized = text
      .replaceAll(RegExp(r'[^\d,.\-]'), '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  return num.tryParse(normalized);
}

int? parseInt(Object? value) => parseNum(value)?.round();

String? emptyToNull(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// Datas guardadas como "2026-10-25" ou "2026-10-25T14:30" (formato dos
/// campos date/datetime-local do HTML original).
DateTime? parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

String formatIsoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

String formatIsoDateTime(DateTime date) =>
    DateFormat("yyyy-MM-dd'T'HH:mm").format(date);

int? parseMillis(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}
