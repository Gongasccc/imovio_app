import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/ai/data/gemini_client.dart';
import 'package:imovio/src/features/ai/data/gemini_repository.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/market_study/application/market_ai_service.dart';
import 'package:imovio/src/features/market_study/application/market_study_calculator.dart';
import 'package:imovio/src/features/market_study/data/market_study_repository.dart';
import 'package:imovio/src/features/market_study/domain/comparable_listing.dart';
import 'package:imovio/src/features/market_study/domain/ine_prices.dart';
import 'package:imovio/src/features/market_study/domain/market_study.dart';
import 'package:imovio/src/features/market_study/domain/study_settings.dart';
import 'package:imovio/src/features/properties/application/listing_import_service.dart';
import 'package:imovio/src/features/properties/data/properties_repository.dart';
import 'package:imovio/src/features/properties/domain/property.dart';
import 'package:imovio/src/utils/format.dart';

part 'market_study_service.g.dart';

/// Estudo de mercado de um imóvel: junta a ficha, a base de comparáveis, os
/// imóveis da carteira e o INE, e recalcula sempre que algum muda.
@riverpod
Future<MarketStudy?> marketStudy(Ref ref, PropertyID propertyId) async {
  final property = await ref.watch(propertyStreamProvider(propertyId).future);
  if (property == null) return null;
  final settings = await ref.watch(
    studySettingsStreamProvider(propertyId).future,
  );
  final saved = await ref.watch(comparablesStreamProvider.future);
  final portfolio = await ref.watch(propertiesStreamProvider.future);
  InePrices? ine;
  try {
    ine = await ref.watch(inePricesProvider.future);
  } catch (_) {
    // Sem dados do INE o estudo faz-se só com comparáveis.
  }
  return MarketStudyCalculator.compute(
    property: property,
    settings: settings,
    comparables: [
      ...saved,
      ...portfolio.map(ComparableListing.fromProperty).nonNulls,
    ],
    ine: ine?.lookup(
      concelho: property.concelho,
      freguesia: property.freguesia,
      distrito: property.distrito,
    ),
  );
}

@riverpod
class MarketStudyController extends _$MarketStudyController {
  @override
  FutureOr<void> build() {}

  Future<MarketAiService> _ai() async {
    final gemini = await ref.read(geminiClientProvider.future);
    if (gemini == null) {
      throw const GeminiException(
        'Configure primeiro a chave do Gemini (ícone da chave no topo).',
      );
    }
    return MarketAiService(gemini);
  }

  /// Procura com o Gemini anúncios semelhantes na zona.
  Future<AreaSearchResult?> searchArea(MarketStudy study) async {
    AreaSearchResult? result;
    final repo = ref.read(marketStudyRepositoryProvider);
    final uid = ref.read(currentUidProvider);
    await _run(() async {
      result = await (await _ai()).searchArea(
        study,
        newId: () => repo.newComparableId(uid),
      );
    });
    return result;
  }

  /// Guarda os anúncios escolhidos e põe-nos no estudo.
  Future<bool> addComparables(
    List<ComparableListing> list,
    PropertyID propertyId,
    StudySettings settings,
  ) => _run(() async {
    final uid = ref.read(currentUidProvider);
    final repo = ref.read(marketStudyRepositoryProvider);
    var next = settings;
    for (final c in list) {
      await repo.saveComparable(uid: uid, comparable: c);
      next = next.toggle(c.id, include: true);
    }
    await repo.saveSettings(uid: uid, propertyId: propertyId, settings: next);
  });

  /// Escreve com o Gemini o comentário de mercado e guarda-o no estudo.
  Future<bool> writeCommentary(MarketStudy study) => _run(() async {
    final text = await (await _ai()).writeCommentary(study);
    await ref
        .read(marketStudyRepositoryProvider)
        .saveSettings(
          uid: ref.read(currentUidProvider),
          propertyId: study.subject.property.id,
          settings: study.settings.copyWith(commentary: text),
        );
  });

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
    return !result.hasError;
  }

  Future<bool> saveSettings(PropertyID propertyId, StudySettings settings) =>
      _run(
        () => ref
            .read(marketStudyRepositoryProvider)
            .saveSettings(
              uid: ref.read(currentUidProvider),
              propertyId: propertyId,
              settings: settings,
            ),
      );

  /// Guarda o comparável na base e garante que entra neste estudo.
  Future<bool> saveComparable(
    ComparableListing comparable, {
    PropertyID? forStudy,
    StudySettings? settings,
  }) => _run(() async {
    final uid = ref.read(currentUidProvider);
    final repo = ref.read(marketStudyRepositoryProvider);
    await repo.saveComparable(uid: uid, comparable: comparable);
    if (forStudy != null && settings != null) {
      await repo.saveSettings(
        uid: uid,
        propertyId: forStudy,
        settings: settings.toggle(comparable.id, include: true),
      );
    }
  });

  Future<bool> deleteComparable(ComparableID id) => _run(
    () => ref
        .read(marketStudyRepositoryProvider)
        .deleteComparable(uid: ref.read(currentUidProvider), id: id),
  );

  /// Lê um anúncio pelo link e devolve um comparável por guardar, para o
  /// utilizador confirmar os campos.
  Future<ComparableListing?> importFromLink(String url) async {
    ComparableListing? draft;
    await _run(() async {
      final listing = await ref.read(listingImportServiceProvider).extract(url);
      final text = [
        ...listing.caracteristicas,
        listing.description ?? '',
      ].join(' ');
      draft = ComparableListing(
        id: ref
            .read(marketStudyRepositoryProvider)
            .newComparableId(ref.read(currentUidProvider)),
        title: listing.title ?? 'Anúncio',
        price: listing.price ?? 0,
        area: listing.areaUtil ?? listing.areaBruta ?? 0,
        negocio: listing.negocio,
        tipo: listing.tipo,
        tipologia: listing.tipologia,
        concelho: listing.concelho,
        freguesia: listing.freguesia,
        morada: listing.morada,
        conservation: Conservation.guess(text),
        garage: ComparableFeatures.garage(text),
        outdoor: ComparableFeatures.outdoor(text),
        elevator: ComparableFeatures.elevator(text),
        sourceUrl: url,
        image: listing.images.firstOrNull,
        date: formatIsoDate(DateTime.now()),
      );
    });
    return draft;
  }

  ComparableListing newManual() => ComparableListing(
    id: ref
        .read(marketStudyRepositoryProvider)
        .newComparableId(ref.read(currentUidProvider)),
    title: '',
    price: 0,
    area: 0,
    date: formatIsoDate(DateTime.now()),
  );
}
