import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Pré-visualização de um PDF com imprimir, partilhar e descarregar.
class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.fileName,
    required this.makePdf,
  });
  final String title;
  final String fileName;
  final Future<Uint8List> Function(PdfPageFormat format) makePdf;

  static Future<void> open(
    BuildContext context, {
    required String title,
    required String fileName,
    required Future<Uint8List> Function(PdfPageFormat format) build,
  }) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            PdfPreviewScreen(title: title, fileName: fileName, makePdf: build),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: makePdf,
        pdfFileName: fileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}
