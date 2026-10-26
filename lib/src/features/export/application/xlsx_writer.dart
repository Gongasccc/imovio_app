import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Uma folha do Excel: nome, cabeçalhos e linhas (texto, número ou data).
class XlsxSheet {
  const XlsxSheet(this.name, this.headers, this.rows);
  final String name;
  final List<String> headers;
  final List<List<Object?>> rows;
}

/// Gera um ficheiro .xlsx simples (cabeçalho a negrito, primeira linha
/// fixa). Escrito à mão porque o pacote "excel" não é compatível com o
/// pacote de PDF que a app usa.
Uint8List buildXlsx(List<XlsxSheet> sheets) {
  String esc(String s) => const HtmlEscape(HtmlEscapeMode.element)
      .convert(s.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), ''));

  String col(int i) {
    var n = i + 1;
    var out = '';
    while (n > 0) {
      final r = (n - 1) % 26;
      out = String.fromCharCode(65 + r) + out;
      n = (n - 1) ~/ 26;
    }
    return out;
  }

  String cell(int r, int c, Object? v, {bool header = false}) {
    final ref = '${col(c)}${r + 1}';
    final style = header ? ' s="1"' : '';
    if (v == null || (v is String && v.isEmpty)) return '';
    if (v is num) return '<c r="$ref"$style><v>$v</v></c>';
    if (v is DateTime) {
      // Datas como texto legível (dd/mm/aaaa hh:mm).
      String two(int n) => n.toString().padLeft(2, '0');
      v = '${two(v.day)}/${two(v.month)}/${v.year}'
          '${v.hour == 0 && v.minute == 0 ? '' : ' ${two(v.hour)}:${two(v.minute)}'}';
    }
    if (v is bool) v = v ? 'Sim' : 'Não';
    if (v is List) v = v.join(', ');
    return '<c r="$ref" t="inlineStr"$style><is><t xml:space="preserve">'
        '${esc(v.toString())}</t></is></c>';
  }

  String sheetXml(XlsxSheet s) {
    final b = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" '
      'topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView>'
      '</sheetViews><cols>',
    );
    for (var c = 0; c < s.headers.length; c++) {
      b.write('<col min="${c + 1}" max="${c + 1}" width="20" customWidth="1"/>');
    }
    b.write('</cols><sheetData>');
    b.write('<row r="1">');
    for (var c = 0; c < s.headers.length; c++) {
      b.write(cell(0, c, s.headers[c], header: true));
    }
    b.write('</row>');
    for (var r = 0; r < s.rows.length; r++) {
      b.write('<row r="${r + 2}">');
      for (var c = 0; c < s.rows[r].length; c++) {
        b.write(cell(r + 1, c, s.rows[r][c]));
      }
      b.write('</row>');
    }
    b.write('</sheetData></worksheet>');
    return b.toString();
  }

  String sheetName(String n) {
    final clean = n.replaceAll(RegExp(r'[\\/?*\[\]:]'), ' ');
    return esc(clean.length > 31 ? clean.substring(0, 31) : clean);
  }

  final archive = Archive()
    ..addFile(ArchiveFile.string(
      '[Content_Types].xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
          '<Default Extension="xml" ContentType="application/xml"/>'
          '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
          '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
          '${[for (var i = 1; i <= sheets.length; i++) '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join()}'
          '</Types>',
    ))
    ..addFile(ArchiveFile.string(
      '_rels/.rels',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
          '</Relationships>',
    ))
    ..addFile(ArchiveFile.string(
      'xl/workbook.xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
          '${[for (var i = 0; i < sheets.length; i++) '<sheet name="${sheetName(sheets[i].name)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'].join()}'
          '</sheets></workbook>',
    ))
    ..addFile(ArchiveFile.string(
      'xl/_rels/workbook.xml.rels',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '${[for (var i = 1; i <= sheets.length; i++) '<Relationship Id="rId$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$i.xml"/>'].join()}'
          '<Relationship Id="rId${sheets.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
          '</Relationships>',
    ))
    ..addFile(ArchiveFile.string(
      'xl/styles.xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
          '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
          '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
          '<fills count="2"><fill><patternFill patternType="none"/></fill>'
          '<fill><patternFill patternType="gray125"/></fill></fills>'
          '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
          '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
          '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
          '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs>'
          '</styleSheet>',
    ));
  for (var i = 0; i < sheets.length; i++) {
    archive.addFile(
        ArchiveFile.string('xl/worksheets/sheet${i + 1}.xml', sheetXml(sheets[i])));
  }
  return ZipEncoder().encodeBytes(archive);
}
