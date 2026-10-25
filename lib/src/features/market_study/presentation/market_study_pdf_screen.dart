import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:imovio/src/common_widgets/async_value_widget.dart';
import 'package:imovio/src/common_widgets/empty_placeholder.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/market_study/application/market_study_pdf.dart';
import 'package:imovio/src/features/market_study/application/market_study_service.dart';
import 'package:imovio/src/features/market_study/domain/market_study.dart';
import 'package:imovio/src/features/properties/domain/property.dart';

/// Pré-visualização do PDF do estudo, com imprimir, partilhar e descarregar.
class MarketStudyPdfScreen extends ConsumerWidget {
  const MarketStudyPdfScreen({super.key, required this.propertyId});
  final PropertyID propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final consultant = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName
        : user?.email;
    return Scaffold(
      appBar: AppBar(title: const Text('PDF do Estudo de Mercado')),
      body: AsyncValueWidget<MarketStudy?>(
        // Usa o estudo tal como está agora; não reconstrói o PDF a cada
        // alteração na base de dados.
        value: ref.watch(marketStudyProvider(propertyId)),
        data: (study) => study == null || study.pricePerM2 == null
            ? const EmptyPlaceholder(
                icon: Icons.picture_as_pdf_outlined,
                message: 'Ainda não há comparáveis suficientes para o estudo.',
              )
            : PdfPreview(
                build: (format) => MarketStudyPdf.build(
                  study,
                  consultant: consultant,
                  format: format,
                ),
                pdfFileName: _fileName(study),
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
              ),
      ),
    );
  }

  static String _fileName(MarketStudy study) {
    final slug = study.subject.property.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'estudo-de-mercado-${slug.isEmpty ? 'imovel' : slug}.pdf';
  }
}
