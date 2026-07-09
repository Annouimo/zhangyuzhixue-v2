/// 章鱼智学 — PreferenceRepository
/// data-db: preference.*
/// 对应页面：preference_welcome.html, preference_list.html, preference_edit.html, profile.html(偏好数)

class PreferenceFilter {
  final List<String> years;
  final List<String> regions;
  final List<String> conceptTags;

  const PreferenceFilter({
    required this.years,
    required this.regions,
    required this.conceptTags,
  });

  factory PreferenceFilter.fromJson(Map<String, dynamic> json) =>
      PreferenceFilter(
        years: (json['years'] as List).cast<String>(),
        regions: (json['regions'] as List).cast<String>(),
        conceptTags: (json['concept_tags'] as List).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'years': years,
        'regions': regions,
        'concept_tags': conceptTags,
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
  static Future<List<PreferenceSummary>> getList() async {
    throw UnimplementedError('PreferenceRepository.getList');
  }

  /// GET /api/preferences/count/
  static Future<int> getCount() async {
    throw UnimplementedError('PreferenceRepository.getCount');
  }

  /// GET /api/preferences/{id}/
  static Future<PreferenceFilter> getEdit(int id) async {
    throw UnimplementedError('PreferenceRepository.getEdit');
  }

  /// POST /api/preferences/
  static Future<void> save({
    required String name,
    required PreferenceFilter filter,
  }) async {
    throw UnimplementedError('PreferenceRepository.save');
  }

  /// DELETE /api/preferences/{id}
  static Future<void> delete(int id) async {
    throw UnimplementedError('PreferenceRepository.delete');
  }
}
