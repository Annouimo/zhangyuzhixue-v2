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

  const PreferenceFilter({
    required this.years,
    required this.regions,
    required this.conceptTags,
  });

  Map<String, dynamic> toJson() => {
        'years': years,
        'regions': regions,
        'concept_tags': conceptTags,
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
    );
  }

  Future<void> delete(int id) => _dao.delete(id);

  List<String> _parseJsonList(String raw) {
    if (raw.isEmpty) return [];
    return raw.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  String _jsonEncode(List<String> items) => '[${items.map((s) => '"$s"').join(',')}]';
}
