import '../data/daos/preference_dao.dart';


/// 筛选预设 — 委托 PreferenceDao
class PreferenceSummary {
  final int id;
  final String name;
  final String summary;

  const PreferenceSummary({
    required this.id,
    required this.name,
    required this.summary,
  });
}

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

class PreferenceRepository {
  final PreferenceDao _dao;
  const PreferenceRepository(this._dao);

  Future<List<PreferenceSummary>> getList() async {
    final rows = await _dao.listAll();
    return rows.map((r) => PreferenceSummary(
      id: r.id,
      name: r.name,
      summary: '${r.years} · ${r.regions}',
    )).toList();
  }

  Future<int> getCount() => _dao.count();

  Future<PreferenceFilter> getEdit(int id) async {
    final row = await _dao.getById(id);
    if (row == null) throw Exception('Preference not found: $id');
    return PreferenceFilter(
      years: _parseJsonList(row.years),
      regions: _parseJsonList(row.regions),
      conceptTags: _parseJsonList(row.conceptTags),
      types: row.types != null ? _parseJsonList(row.types!) : [],
      diffMin: row.diffMin,
      diffMax: row.diffMax,
      calcMin: row.calcMin,
      calcMax: row.calcMax,
    );
  }

  Future<void> save({
    required String name,
    required PreferenceFilter filter,
  }) async {
    await _dao.save(
      name: name,
      years: _jsonEncode(filter.years),
      regions: _jsonEncode(filter.regions),
      conceptTags: _jsonEncode(filter.conceptTags),
      types: filter.types.isNotEmpty ? _jsonEncode(filter.types) : null,
      diffMin: filter.diffMin,
      diffMax: filter.diffMax,
      calcMin: filter.calcMin,
      calcMax: filter.calcMax,
    );
  }

  Future<void> delete(int id) => _dao.delete(id);

  List<String> _parseJsonList(String raw) {
    if (raw.isEmpty) return [];
    return raw.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  String _jsonEncode(List<String> items) => '[${items.map((s) => '"$s"').join(',')}]';
}
