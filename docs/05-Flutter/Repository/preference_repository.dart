/// 章鱼智学 — PreferenceRepository
/// data-db: preference.*
/// 对应页面：preference_welcome.html, preference_list.html, preference_edit.html, profile.html(偏好数)

class PreferenceFilter {
  final List<String> years;
  final List<String> regions;
  final List<String> conceptTags;
  final List<String> types;
  final double? diffMin;
  final double? diffMax;
  final double? calcMin;
  final double? calcMax;

  const PreferenceFilter({
    required this.years,
    required this.regions,
    required this.conceptTags,
    this.types = const [],
    this.diffMin,
    this.diffMax,
    this.calcMin,
    this.calcMax,
  });

  factory PreferenceFilter.fromJson(Map<String, dynamic> json) =>
      PreferenceFilter(
        years: (json['years'] as List).cast<String>(),
        regions: (json['regions'] as List).cast<String>(),
        conceptTags: (json['concept_tags'] as List).cast<String>(),
        types: (json['types'] as List?)?.cast<String>() ?? [],
        diffMin: (json['diff_min'] as num?)?.toDouble(),
        diffMax: (json['diff_max'] as num?)?.toDouble(),
        calcMin: (json['calc_min'] as num?)?.toDouble(),
        calcMax: (json['calc_max'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'years': years,
        'regions': regions,
        'concept_tags': conceptTags,
        if (types.isNotEmpty) 'types': types,
        if (diffMin != null) 'diff_min': diffMin,
        if (diffMax != null) 'diff_max': diffMax,
        if (calcMin != null) 'calc_min': calcMin,
        if (calcMax != null) 'calc_max': calcMax,
      };
}

class PreferenceSummary {
  final int id;
  final String name;
  final String summary;

  const PreferenceSummary({
    required this.id,
    required this.name,
    required this.summary,
  });

  factory PreferenceSummary.fromJson(Map<String, dynamic> json) =>
      PreferenceSummary(
        id: json['id'] as int,
        name: json['name'] as String,
        summary: json['summary'] as String,
      );
}

class PreferenceRepository {
  /// GET /api/preferences/
  Future<List<PreferenceSummary>> getList() async {
    throw UnimplementedError('PreferenceRepository.getList');
  }

  /// GET /api/preferences/count/
  Future<int> getCount() async {
    throw UnimplementedError('PreferenceRepository.getCount');
  }

  /// GET /api/preferences/{id}/
  Future<PreferenceFilter> getEdit(int id) async {
    throw UnimplementedError('PreferenceRepository.getEdit');
  }

  /// POST /api/preferences/
  Future<void> save({
    required String name,
    required PreferenceFilter filter,
  }) async {
    throw UnimplementedError('PreferenceRepository.save');
  }

  /// DELETE /api/preferences/{id}
  Future<void> delete(int id) async {
    throw UnimplementedError('PreferenceRepository.delete');
  }
}
