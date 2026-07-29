import '../domain/models.dart';

/// Complete value passed between a filter panel and its consumer.
class FilterState {
  final Set<String> years;
  final Set<String> regions;
  final Set<String> types;
  final Set<String> conceptTags;
  final Set<String> examTypes;
  final Set<String> knowledgeCards;
  final double diffMin;
  final double diffMax;
  final double calcMin;
  final double calcMax;
  final SortMode? sort;

  const FilterState({
    this.years = const {},
    this.regions = const {},
    this.types = const {},
    this.conceptTags = const {},
    this.examTypes = const {},
    this.knowledgeCards = const {},
    this.diffMin = 0,
    this.diffMax = 10,
    this.calcMin = 0,
    this.calcMax = 10,
    this.sort,
  });

  bool get hasContentRange =>
      years.isNotEmpty ||
      regions.isNotEmpty ||
      conceptTags.isNotEmpty ||
      examTypes.isNotEmpty ||
      knowledgeCards.isNotEmpty;

  FilterState copyWith({
    Set<String>? years,
    Set<String>? regions,
    Set<String>? types,
    Set<String>? conceptTags,
    Set<String>? examTypes,
    Set<String>? knowledgeCards,
    double? diffMin,
    double? diffMax,
    double? calcMin,
    double? calcMax,
    SortMode? sort,
  }) {
    return FilterState(
      years: years ?? this.years,
      regions: regions ?? this.regions,
      types: types ?? this.types,
      conceptTags: conceptTags ?? this.conceptTags,
      examTypes: examTypes ?? this.examTypes,
      knowledgeCards: knowledgeCards ?? this.knowledgeCards,
      diffMin: diffMin ?? this.diffMin,
      diffMax: diffMax ?? this.diffMax,
      calcMin: calcMin ?? this.calcMin,
      calcMax: calcMax ?? this.calcMax,
      sort: sort ?? this.sort,
    );
  }
}

typedef FilterChangedCallback = void Function(FilterState state);
