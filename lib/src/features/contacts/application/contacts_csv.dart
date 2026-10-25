import 'package:imovio/src/features/contacts/domain/contact.dart';

/// Gera o CSV de contactos com as mesmas colunas da app original, mais NIF e
/// cidade. Aspas dentro dos valores são escapadas.
String contactsToCsv(List<Contact> contacts) {
  String cell(String? value) => '"${(value ?? '').replaceAll('"', '""')}"';
  final buffer = StringBuffer(
    'Nome,Email,Telefone,Tipo,Origem,Morada,Código Postal,Cidade,NIF\n',
  );
  for (final c in contacts) {
    buffer.writeln([
      c.name,
      c.email,
      c.phone,
      c.type,
      c.origin,
      c.address,
      c.zip,
      c.city,
      c.nif,
    ].map(cell).join(','));
  }
  return buffer.toString();
}
