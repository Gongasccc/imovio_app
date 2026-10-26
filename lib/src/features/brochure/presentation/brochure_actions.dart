import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:imovio/src/features/brochure/application/cpcv_sheet_pdf.dart';
import 'package:imovio/src/features/brochure/application/pdf_common.dart';
import 'package:imovio/src/features/brochure/application/property_brochure_pdf.dart';
import 'package:imovio/src/features/brochure/presentation/pdf_preview_screen.dart';
import 'package:imovio/src/features/contacts/domain/contact.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';
import 'package:imovio/src/features/properties/domain/property.dart';

// Ponto de entrada dos PDFs, importado com "deferred" pelos ecrãs: o código
// dos PDFs só é descarregado quando se abre um.

void openPropertyBrochure(
  BuildContext context,
  Property property, {
  String? consultant,
  String? consultantEmail,
}) =>
    PdfPreviewScreen.open(
      context,
      title: 'Ficha do imóvel',
      fileName: 'imovel-${pdfSlug(property.title)}.pdf',
      build: (format) async {
        final client = http.Client();
        try {
          return await PropertyBrochurePdf.build(
            property,
            client: client,
            consultant: consultant,
            consultantEmail: consultantEmail,
            format: format,
          );
        } finally {
          client.close();
        }
      },
    );

void openCpcvSheet(
  BuildContext context, {
  required Deal deal,
  Contact? buyer,
  Contact? seller,
  Property? property,
  String? consultant,
}) =>
    PdfPreviewScreen.open(
      context,
      title: 'Ficha para o CPCV',
      fileName: 'ficha-cpcv-${pdfSlug(deal.title)}.pdf',
      build: (format) => CpcvSheetPdf.build(
        deal: deal,
        buyer: buyer,
        seller: seller,
        property: property,
        consultant: consultant,
        format: format,
      ),
    );
