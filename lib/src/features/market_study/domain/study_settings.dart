import 'package:equatable/equatable.dart';
import 'package:imovio/src/features/market_study/domain/comparable_listing.dart';
import 'package:imovio/src/utils/format.dart';

/// Coeficientes de homogeneização, em fração (0.05 = 5 %). Os valores por
/// defeito são os usados habitualmente em estudos de mercado residenciais e
/// podem ser ajustados em cada estudo.
class StudyCoefficients extends Equatable {
  const StudyCoefficients({
    this.negotiation = 0.05,
    this.areaElasticity = 0.15,
    this.conservationStep = 0.08,
    this.garage = 0.05,
    this.outdoor = 0.03,
    this.elevator = 0.04,
  });

  /// Desconto do preço pedido para o valor de fecho (só em anúncios).
  final double negotiation;

  /// Quanto o €/m² desce quando a área sobe: casas maiores têm €/m² mais
  /// baixo. Fator = (área do comparável / área do imóvel) ^ elasticidade.
  final double areaElasticity;

  /// Ajuste por cada nível de diferença no estado de conservação.
  final double conservationStep;
  final double garage;
  final double outdoor;

  /// Só se aplica a apartamentos.
  final double elevator;

  static const defaults = StudyCoefficients();

  factory StudyCoefficients.fromMap(Map<String, dynamic>? data) {
    double v(String key, double fallback) =>
        parseNum(data?[key])?.toDouble() ?? fallback;
    return StudyCoefficients(
      negotiation: v('negotiation', defaults.negotiation),
      areaElasticity: v('areaElasticity', defaults.areaElasticity),
      conservationStep: v('conservationStep', defaults.conservationStep),
      garage: v('garage', defaults.garage),
      outdoor: v('outdoor', defaults.outdoor),
      elevator: v('elevator', defaults.elevator),
    );
  }

  Map<String, dynamic> toMap() => {
    'negotiation': negotiation,
    'areaElasticity': areaElasticity,
    'conservationStep': conservationStep,
    'garage': garage,
    'outdoor': outdoor,
    'elevator': elevator,
  };

  StudyCoefficients copyWith({
    double? negotiation,
    double? areaElasticity,
    double? conservationStep,
    double? garage,
    double? outdoor,
    double? elevator,
  }) => StudyCoefficients(
    negotiation: negotiation ?? this.negotiation,
    areaElasticity: areaElasticity ?? this.areaElasticity,
    conservationStep: conservationStep ?? this.conservationStep,
    garage: garage ?? this.garage,
    outdoor: outdoor ?? this.outdoor,
    elevator: elevator ?? this.elevator,
  );

  @override
  List<Object?> get props => toMap().values.toList();
}

/// Escolhas do estudo de um imóvel, em `users/{uid}/estudos/{propertyId}`.
/// O que fica a null é deduzido da ficha do imóvel.
class StudySettings extends Equatable {
  const StudySettings({
    this.conservation,
    this.garage,
    this.outdoor,
    this.elevator,
    this.coefficients = StudyCoefficients.defaults,
    this.included = const {},
    this.excluded = const {},
    this.location = const {},
    this.notes,
  });

  final Conservation? conservation;
  final bool? garage;
  final bool? outdoor;
  final bool? elevator;
  final StudyCoefficients coefficients;

  /// Comparáveis acrescentados à mão, além da escolha automática.
  final Set<ComparableID> included;

  /// Comparáveis retirados da escolha automática.
  final Set<ComparableID> excluded;

  /// Ajuste de localização por comparável (0.1 = o imóvel está 10 % melhor
  /// localizado do que o comparável).
  final Map<ComparableID, double> location;
  final String? notes;

  factory StudySettings.fromMap(Map<String, dynamic>? data) {
    Set<String> ids(String key) => {
      ...?(data?[key] as List?)?.map((e) => e.toString()),
    };
    bool? b(String key) => data?[key] is bool ? data![key] as bool : null;
    final rawLocation = data?['location'];
    return StudySettings(
      conservation: Conservation.fromName(data?['conservation']),
      garage: b('garage'),
      outdoor: b('outdoor'),
      elevator: b('elevator'),
      coefficients: StudyCoefficients.fromMap(
        data?['coefficients'] as Map<String, dynamic>?,
      ),
      included: ids('included'),
      excluded: ids('excluded'),
      location: rawLocation is Map
          ? {
              for (final e in rawLocation.entries)
                if (parseNum(e.value) != null)
                  e.key.toString(): parseNum(e.value)!.toDouble(),
            }
          : const {},
      notes: emptyToNull(data?['notes']?.toString()),
    );
  }

  Map<String, dynamic> toMap() => {
    'conservation': conservation?.name,
    'garage': garage,
    'outdoor': outdoor,
    'elevator': elevator,
    'coefficients': coefficients.toMap(),
    'included': included.toList(),
    'excluded': excluded.toList(),
    'location': location,
    'notes': notes ?? '',
  };

  StudySettings copyWith({
    Conservation? conservation,
    bool? garage,
    bool? outdoor,
    bool? elevator,
    StudyCoefficients? coefficients,
    Set<ComparableID>? included,
    Set<ComparableID>? excluded,
    Map<ComparableID, double>? location,
    String? notes,
  }) => StudySettings(
    conservation: conservation ?? this.conservation,
    garage: garage ?? this.garage,
    outdoor: outdoor ?? this.outdoor,
    elevator: elevator ?? this.elevator,
    coefficients: coefficients ?? this.coefficients,
    included: included ?? this.included,
    excluded: excluded ?? this.excluded,
    location: location ?? this.location,
    notes: notes ?? this.notes,
  );

  /// Liga ou desliga um comparável no estudo.
  StudySettings toggle(ComparableID id, {required bool include}) => copyWith(
    included: include ? {...included, id} : ({...included}..remove(id)),
    excluded: include ? ({...excluded}..remove(id)) : {...excluded, id},
  );

  @override
  List<Object?> get props => [
    conservation,
    garage,
    outdoor,
    elevator,
    coefficients,
    included,
    excluded,
    location,
    notes,
  ];
}
