import 'package:drift/drift.dart';
import '../database/app_database.dart' as db;

/// 筛选预设数据访问层（user 库）
class PreferenceDao {
  final db.AppDatabase _db;
  const PreferenceDao(this._db);

  Future<List<db.PreferenceFilterRow>> listAll() async {
    final rows = await _db.customSelect(
      'SELECT * FROM preference_filters ORDER BY id',
      readsFrom: {_db.preferenceFilters},
    ).get();
    return rows.map((r) => _db.preferenceFilters.map(r.data)).toList();
  }

  Future<db.PreferenceFilterRow?> getById(int id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM preference_filters WHERE id = ?',
      variables: [Variable(id)],
      readsFrom: {_db.preferenceFilters},
    ).get();
    if (rows.isEmpty) return null;
    return _db.preferenceFilters.map(rows.first.data);
  }

  Future<int> save({
    required String name,
    required String years,
    required String regions,
    required String conceptTags,
  }) =>
      _db.into(_db.preferenceFilters).insert(db.PreferenceFiltersCompanion(
        name: Value(name),
        years: Value(years),
        regions: Value(regions),
        conceptTags: Value(conceptTags),
      ));

  Future<void> delete(int id) async {
    final q = _db.delete(_db.preferenceFilters);
    q.where((t) => t.id.equals(id));
    await q.go();
  }

  Future<int> count() async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM preference_filters',
      readsFrom: {_db.preferenceFilters},
    ).getSingle();
    return row.read<int>('c')!;
  }
}
