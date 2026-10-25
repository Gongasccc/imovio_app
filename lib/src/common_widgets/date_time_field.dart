import 'package:flutter/material.dart';
import 'package:imovio/src/utils/format.dart';

/// Escolha de data (e hora, se [withTime]) num campo de formulário.
class DateTimeField extends StatelessWidget {
  const DateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.withTime = true,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool withTime;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    if (!withTime) {
      onChanged(date);
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value ?? now),
    );
    onChanged(DateTime(date.year, date.month, date.day, time?.hour ?? 10,
        time?.minute ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? ''
        : (withTime ? Format.dateTime(value) : Format.date(value));
    return InkWell(
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today_outlined, size: 18)
              : IconButton(
                  tooltip: 'Limpar',
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                ),
        ),
        isEmpty: value == null,
        child: Text(text),
      ),
    );
  }
}
